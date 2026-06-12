<?php

namespace App\Models;

use Database\Factories\StoryFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Story extends Model
{
    /** @use HasFactory<StoryFactory> */
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'media_path',
        'caption',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function views(): HasMany
    {
        return $this->hasMany(StoryView::class);
    }

    public function viewedByUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'story_views')
            ->withTimestamps();
    }

    public function scopeVisibleTo(Builder $query, User $viewer): Builder
    {
        return $query->where(function (Builder $query) use ($viewer): void {
            $query->where('user_id', $viewer->id)
                ->orWhereHas('user', fn (Builder $userQuery) => $userQuery->where('is_private', false))
                ->orWhereExists(function ($subQuery) use ($viewer): void {
                    $subQuery->selectRaw('1')
                        ->from('follows')
                        ->whereColumn('follows.following_id', 'stories.user_id')
                        ->where('follows.follower_id', $viewer->id)
                        ->where('follows.status', Follow::STATUS_ACCEPTED);
                });
        });
    }
}
