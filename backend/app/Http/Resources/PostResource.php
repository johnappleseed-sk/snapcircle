<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $likedByMe = $this->liked_by_me;
        $savedByMe = $this->saved_by_me;
        $isOwner = $request->user()?->id === $this->user_id;

        if ($likedByMe === null && $request->user()) {
            $likedByMe = $this->likes()
                ->where('user_id', $request->user()->id)
                ->exists();
        }

        if ($savedByMe === null && $request->user()) {
            $savedByMe = $this->savedPosts()
                ->where('user_id', $request->user()->id)
                ->exists();
        }

        return [
            'id' => $this->id,
            'content' => $this->content,
            'image_path' => $this->image_path,
            'image_url' => $this->image_path ? asset('storage/'.$this->image_path) : null,
            'likes_count' => $this->likes_count ?? $this->likes()->count(),
            'comments_count' => $this->comments_count ?? $this->comments()->count(),
            'saves_count' => $this->saved_posts_count ?? $this->savedPosts()->count(),
            'liked_by_me' => (bool) $likedByMe,
            'saved_by_me' => (bool) $savedByMe,
            'is_owner' => $isOwner,
            'can_update' => $isOwner,
            'can_delete' => $isOwner,
            'user' => UserResource::make($this->whenLoaded('user')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
