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
        $authUser = $request->user();
        $likedByMe = $this->liked_by_me;
        $savedByMe = $this->saved_by_me;
        $isOwner = $authUser?->id === $this->user_id;

        if ($likedByMe === null && $authUser) {
            $likedByMe = $this->likes()
                ->where('user_id', $authUser->id)
                ->exists();
        }

        if ($savedByMe === null && $authUser) {
            $savedByMe = $this->savedPosts()
                ->where('user_id', $authUser->id)
                ->exists();
        }

        $media = $this->relationLoaded('media') ? $this->media : $this->media()->get();
        $mediaItems = $media->map(fn ($item): array => [
            'id' => $item->id,
            'url' => str_starts_with($item->path, 'http')
                ? $item->path
                : asset('storage/'.$item->path),
            'path' => $item->path,
            'type' => $item->type,
            'sort_order' => (int) $item->sort_order,
        ])->values();

        if ($mediaItems->isEmpty() && $this->image_path) {
            $mediaItems->push([
                'id' => null,
                'url' => str_starts_with($this->image_path, 'http')
                    ? $this->image_path
                    : asset('storage/'.$this->image_path),
                'path' => $this->image_path,
                'type' => 'image',
                'sort_order' => 0,
            ]);
        }

        $primaryMedia = $mediaItems->first();

        return [
            'id' => $this->id,
            'content' => $this->content,
            'image_path' => $this->image_path,
            'image_url' => $primaryMedia['url'] ?? null,
            'media' => $mediaItems,
            'likes_count' => array_key_exists('likes_count', $this->resource->getAttributes())
                ? (int) $this->likes_count
                : $this->likes()->count(),
            'comments_count' => array_key_exists('comments_count', $this->resource->getAttributes())
                ? (int) $this->comments_count
                : $this->comments()->count(),
            'saves_count' => array_key_exists('saved_posts_count', $this->resource->getAttributes())
                ? (int) $this->saved_posts_count
                : $this->savedPosts()->count(),
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
