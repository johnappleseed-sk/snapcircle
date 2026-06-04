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

        if ($likedByMe === null && $request->user()) {
            $likedByMe = $this->likes()
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
            'liked_by_me' => (bool) $likedByMe,
            'user' => UserResource::make($this->whenLoaded('user')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
