<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'email_verified_at',
        'username',
        'password',
        'avatar',
        'cover_image',
        'bio',
        'location',
        'website',
        'date_of_birth',
        'is_private',
        'last_active_at',
        'account_status',
        'role',
        'banned_at',
        'ban_reason',
        'provider',
        'provider_id',
    ];

    protected $attributes = [
        'account_status' => 'active',
        'role' => 'user',
        'is_private' => false,
    ];

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    public function likes(): HasMany
    {
        return $this->hasMany(Like::class);
    }

    public function savedPosts(): HasMany
    {
        return $this->hasMany(SavedPost::class);
    }

    public function savedPostItems(): BelongsToMany
    {
        return $this->belongsToMany(Post::class, 'saved_posts')
            ->withTimestamps();
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }

    public function actedNotifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'actor_id');
    }

    public function conversations(): BelongsToMany
    {
        return $this->belongsToMany(Conversation::class)
            ->withTimestamps();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function stories(): HasMany
    {
        return $this->hasMany(Story::class);
    }

    public function storyViews(): HasMany
    {
        return $this->hasMany(StoryView::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class, 'reporter_id');
    }

    public function reviewedReports(): HasMany
    {
        return $this->hasMany(Report::class, 'reviewed_by');
    }

    public function receivedReports(): MorphMany
    {
        return $this->morphMany(Report::class, 'reportable');
    }

    public function blocks(): HasMany
    {
        return $this->hasMany(UserBlock::class, 'blocker_id');
    }

    public function blockedBy(): HasMany
    {
        return $this->hasMany(UserBlock::class, 'blocked_id');
    }

    public function blockedUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_blocks', 'blocker_id', 'blocked_id')
            ->withTimestamps();
    }

    public function blockedByUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_blocks', 'blocked_id', 'blocker_id')
            ->withTimestamps();
    }

    public function hasBlocked(User $user): bool
    {
        return $this->blocks()
            ->where('blocked_id', $user->id)
            ->exists();
    }

    public function isBlockingOrBlockedBy(User $user): bool
    {
        return UserBlock::query()
            ->where(function ($query) use ($user): void {
                $query->where('blocker_id', $this->id)
                    ->where('blocked_id', $user->id);
            })
            ->orWhere(function ($query) use ($user): void {
                $query->where('blocker_id', $user->id)
                    ->where('blocked_id', $this->id);
            })
            ->exists();
    }

    /**
     * @return array<int, int>
     */
    public function blockedUserIds(): array
    {
        $blocked = $this->blocks()->pluck('blocked_id');
        $blockedBy = $this->blockedBy()->pluck('blocker_id');

        return $blocked
            ->merge($blockedBy)
            ->unique()
            ->values()
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    public function setting(): HasOne
    {
        return $this->hasOne(UserSetting::class);
    }

    public function followers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'follows', 'following_id', 'follower_id')
            ->wherePivot('status', Follow::STATUS_ACCEPTED)
            ->withPivot('status')
            ->withTimestamps();
    }

    public function following(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'follows', 'follower_id', 'following_id')
            ->wherePivot('status', Follow::STATUS_ACCEPTED)
            ->withPivot('status')
            ->withTimestamps();
    }

    public function pendingFollowRequests(): HasMany
    {
        return $this->hasMany(Follow::class, 'following_id')
            ->where('status', Follow::STATUS_PENDING);
    }

    public function sentFollowRequests(): HasMany
    {
        return $this->hasMany(Follow::class, 'follower_id')
            ->where('status', Follow::STATUS_PENDING);
    }

    public function isAcceptedFollower(User $user): bool
    {
        if ($this->id === $user->id) {
            return true;
        }

        return Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $this->id)
            ->where('status', Follow::STATUS_ACCEPTED)
            ->exists();
    }

    public function hasPendingFollowRequestFrom(User $user): bool
    {
        return Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $this->id)
            ->where('status', Follow::STATUS_PENDING)
            ->exists();
    }

    public function canViewPrivateContent(User $viewer): bool
    {
        if ($this->id === $viewer->id) {
            return true;
        }

        if ($viewer->isBlockingOrBlockedBy($this)) {
            return false;
        }

        return ! $this->is_private || $this->isAcceptedFollower($viewer);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'date_of_birth' => 'date',
            'is_private' => 'boolean',
            'last_active_at' => 'datetime',
            'banned_at' => 'datetime',
        ];
    }
}
