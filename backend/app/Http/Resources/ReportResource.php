<?php

namespace App\Http\Resources;

use App\Models\Comment;
use App\Models\Post;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReportResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->previewType(),
            'reason' => $this->reason,
            'description' => $this->description,
            'status' => $this->status,
            'action_taken' => $this->action_taken,
            'created_at' => $this->created_at?->toISOString(),
            'reviewed_at' => $this->reviewed_at?->toISOString(),
            'reporter' => UserResource::make($this->whenLoaded('reporter')),
            'reviewer' => UserResource::make($this->whenLoaded('reviewer')),
            'reportable_preview' => $this->reportablePreview(),
        ];
    }

    private function previewType(): string
    {
        return match ($this->reportable_type) {
            Post::class => 'post',
            Comment::class => 'comment',
            User::class => 'user',
            default => class_basename((string) $this->reportable_type),
        };
    }

    /**
     * @return array<string, mixed>|null
     */
    private function reportablePreview(): ?array
    {
        $reportable = $this->whenLoaded('reportable');

        if ($reportable instanceof \Illuminate\Http\Resources\MissingValue || $reportable === null) {
            return null;
        }

        if ($reportable instanceof Post) {
            return [
                'id' => $reportable->id,
                'type' => 'post',
                'content_preview' => str($reportable->content ?? '')->limit(120)->toString(),
                'image_url' => $reportable->image_path ? asset('storage/'.$reportable->image_path) : null,
                'owner' => $reportable->relationLoaded('user')
                    ? UserResource::make($reportable->user)
                    : null,
            ];
        }

        if ($reportable instanceof Comment) {
            return [
                'id' => $reportable->id,
                'type' => 'comment',
                'comment_preview' => str($reportable->comment ?? '')->limit(120)->toString(),
                'owner' => $reportable->relationLoaded('user')
                    ? UserResource::make($reportable->user)
                    : null,
            ];
        }

        if ($reportable instanceof User) {
            return [
                'id' => $reportable->id,
                'type' => 'user',
                'name' => $reportable->name,
                'username' => $reportable->username,
                'avatar_url' => $reportable->avatar && ! str_starts_with($reportable->avatar, 'http')
                    ? asset('storage/'.$reportable->avatar)
                    : $reportable->avatar,
            ];
        }

        return null;
    }
}
