<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SettingsResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'allow_messages' => (bool) $this->allow_messages,
            'show_email' => (bool) $this->show_email,
            'push_notifications_enabled' => (bool) $this->push_notifications_enabled,
            'notify_likes' => (bool) $this->notify_likes,
            'notify_comments' => (bool) $this->notify_comments,
            'notify_follows' => (bool) $this->notify_follows,
            'notify_follow_requests' => (bool) $this->notify_follow_requests,
            'notify_messages' => (bool) $this->notify_messages,
            'notify_mentions' => (bool) $this->notify_mentions,
            'email_notifications_enabled' => (bool) $this->email_notifications_enabled,
            'marketing_emails_enabled' => (bool) $this->marketing_emails_enabled,
            'is_private' => (bool) ($this->user?->is_private ?? false),
            'account_status' => $this->user?->account_status ?? 'active',
        ];
    }
}
