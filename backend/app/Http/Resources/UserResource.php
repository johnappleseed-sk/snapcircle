<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $authUser = $request->user();
        $isFollowedByMe = $this->is_followed_by_me;

        if ($isFollowedByMe === null && $authUser && $authUser->id !== $this->id) {
            $isFollowedByMe = $this->followers()
                ->where('follower_id', $authUser->id)
                ->exists();
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'avatar' => $this->avatar,
            'avatar_url' => $this->avatar && ! str_starts_with($this->avatar, 'http')
                ? asset('storage/'.$this->avatar)
                : $this->avatar,
            'bio' => $this->bio,
            'provider' => $this->provider,
            'posts_count' => $this->posts_count ?? $this->posts()->count(),
            'followers_count' => $this->followers_count ?? $this->followers()->count(),
            'following_count' => $this->following_count ?? $this->following()->count(),
            'is_me' => $authUser?->id === $this->id,
            'is_followed_by_me' => (bool) $isFollowedByMe,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
