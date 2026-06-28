<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserSetting extends Model
{
    protected $fillable = [
        'user_id',
        'allow_messages',
        'show_email',
        'push_notifications_enabled',
        'notify_likes',
        'notify_comments',
        'notify_follows',
        'notify_follow_requests',
        'notify_messages',
        'notify_mentions',
        'email_notifications_enabled',
        'marketing_emails_enabled',
    ];

    protected $attributes = [
        'allow_messages' => true,
        'show_email' => false,
        'push_notifications_enabled' => true,
        'notify_likes' => true,
        'notify_comments' => true,
        'notify_follows' => true,
        'notify_follow_requests' => true,
        'notify_messages' => true,
        'notify_mentions' => true,
        'email_notifications_enabled' => false,
        'marketing_emails_enabled' => false,
    ];

    protected function casts(): array
    {
        return [
            'allow_messages' => 'boolean',
            'show_email' => 'boolean',
            'push_notifications_enabled' => 'boolean',
            'notify_likes' => 'boolean',
            'notify_comments' => 'boolean',
            'notify_follows' => 'boolean',
            'notify_follow_requests' => 'boolean',
            'notify_messages' => 'boolean',
            'notify_mentions' => 'boolean',
            'email_notifications_enabled' => 'boolean',
            'marketing_emails_enabled' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
