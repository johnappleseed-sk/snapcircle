<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PostMedia extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'post_id',
        'path',
        'type',
        'sort_order',
    ];

    /**
     * @return BelongsTo<Post, PostMedia>
     */
    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }
}
