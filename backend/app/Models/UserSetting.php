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
        'email_notifications_enabled',
        'marketing_emails_enabled',
    ];

    protected $attributes = [
        'allow_messages' => true,
        'show_email' => false,
        'push_notifications_enabled' => true,
        'email_notifications_enabled' => false,
        'marketing_emails_enabled' => false,
    ];

    protected function casts(): array
    {
        return [
            'allow_messages' => 'boolean',
            'show_email' => 'boolean',
            'push_notifications_enabled' => 'boolean',
            'email_notifications_enabled' => 'boolean',
            'marketing_emails_enabled' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
