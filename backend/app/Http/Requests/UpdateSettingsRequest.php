<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'allow_messages' => ['nullable', 'boolean'],
            'show_email' => ['nullable', 'boolean'],
            'push_notifications_enabled' => ['nullable', 'boolean'],
            'notify_likes' => ['nullable', 'boolean'],
            'notify_comments' => ['nullable', 'boolean'],
            'notify_follows' => ['nullable', 'boolean'],
            'notify_follow_requests' => ['nullable', 'boolean'],
            'notify_messages' => ['nullable', 'boolean'],
            'notify_mentions' => ['nullable', 'boolean'],
            'email_notifications_enabled' => ['nullable', 'boolean'],
            'marketing_emails_enabled' => ['nullable', 'boolean'],
        ];
    }
}
