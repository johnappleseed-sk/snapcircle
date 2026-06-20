<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class StoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $authUser = $request->user();
        $isOwner = $authUser?->id === $this->user_id;
        $viewedByMe = $this->viewed_by_me;
        $myReaction = $this->my_reaction;

        if ($viewedByMe === null && $authUser) {
            $viewedByMe = $this->views()
                ->where('user_id', $authUser->id)
                ->exists();
        }

        if ($myReaction === null && $authUser) {
            $myReaction = $this->reactions()
                ->where('user_id', $authUser->id)
                ->value('reaction');
        }

        return [
            'id' => $this->id,
            'caption' => $this->caption,
            'media_url' => $this->media_path && ! str_starts_with($this->media_path, 'http')
                ? Storage::disk('public')->url($this->media_path)
                : $this->media_path,
            'expires_at' => $this->expires_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'is_expired' => $this->expires_at?->isPast() ?? true,
            'views_count' => array_key_exists('views_count', $this->resource->getAttributes())
                ? (int) $this->views_count
                : $this->views()->count(),
            'reactions_count' => array_key_exists('reactions_count', $this->resource->getAttributes())
                ? (int) $this->reactions_count
                : $this->reactions()->count(),
            'replies_count' => array_key_exists('replies_count', $this->resource->getAttributes())
                ? (int) $this->replies_count
                : $this->replies()->count(),
            'viewed_by_me' => (bool) $viewedByMe,
            'my_reaction' => $myReaction,
            'is_owner' => $isOwner,
            'can_delete' => $isOwner,
            'user' => UserResource::make($this->whenLoaded('user')),
        ];
    }
}
