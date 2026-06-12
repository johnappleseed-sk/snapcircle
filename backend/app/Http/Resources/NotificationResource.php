<?php

namespace App\Http\Resources;

use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'message' => $this->message(),
            'is_read' => $this->read_at !== null,
            'read_at' => $this->read_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'actor' => $this->actor ? UserResource::make($this->actor) : null,
            'post' => $this->post ? [
                'id' => $this->post->id,
                'content' => $this->post->content,
                'image_url' => $this->post->image_path ? asset('storage/'.$this->post->image_path) : null,
            ] : null,
            'comment' => $this->comment ? [
                'id' => $this->comment->id,
                'comment' => $this->comment->comment,
            ] : null,
            'data' => $this->data,
        ];
    }

    private function message(): string
    {
        $actorName = $this->actor?->name
            ?? ($this->data['actor_name'] ?? 'Someone');

        return match ($this->type) {
            Notification::TYPE_POST_LIKED => "{$actorName} liked your post.",
            Notification::TYPE_POST_COMMENTED => "{$actorName} commented on your post.",
            Notification::TYPE_USER_FOLLOWED => "{$actorName} started following you.",
            Notification::TYPE_FOLLOW_REQUESTED => "{$actorName} requested to follow you.",
            Notification::TYPE_FOLLOW_REQUEST_APPROVED => "{$actorName} approved your follow request.",
            default => 'You have a new notification.',
        };
    }
}
