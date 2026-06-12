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
        $followStatus = $this->follow_status;
        $settings = $this->whenLoaded('setting');
        if ($settings instanceof \Illuminate\Http\Resources\MissingValue) {
            $settings = $this->setting()->first();
        }
        $showEmail = (bool) ($settings?->show_email ?? false);
        $isMe = $authUser?->id === $this->id;

        if ($isFollowedByMe === null && $authUser && $authUser->id !== $this->id) {
            $isFollowedByMe = $this->followers()
                ->where('follower_id', $authUser->id)
                ->exists();
        }

        $isBlockedByMe = $this->is_blocked_by_me;
        $hasBlockedMe = $this->has_blocked_me;
        if ($authUser && $authUser->id !== $this->id) {
            $isBlockedByMe ??= $authUser->hasBlocked($this->resource);
            $hasBlockedMe ??= $this->resource->hasBlocked($authUser);
        }

        if ($followStatus === null && $authUser) {
            $hasRequestedFollow = array_key_exists('has_requested_follow', $this->resource->getAttributes())
                ? (bool) $this->has_requested_follow
                : $this->hasPendingFollowRequestFrom($authUser);

            $followStatus = match (true) {
                $authUser->id === $this->id => 'own_profile',
                (bool) $isBlockedByMe || (bool) $hasBlockedMe => 'blocked',
                (bool) $isFollowedByMe => 'following',
                $hasRequestedFollow => 'requested',
                default => 'not_following',
            };
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $isMe || $showEmail ? $this->email : null,
            'avatar' => $this->avatar,
            'avatar_url' => $this->avatar && ! str_starts_with($this->avatar, 'http')
                ? asset('storage/'.$this->avatar)
                : $this->avatar,
            'cover_image' => $this->cover_image,
            'cover_image_url' => $this->cover_image && ! str_starts_with($this->cover_image, 'http')
                ? asset('storage/'.$this->cover_image)
                : $this->cover_image,
            'bio' => $this->bio,
            'location' => $this->location,
            'website' => $this->website,
            'is_private' => (bool) $this->is_private,
            'allow_messages' => (bool) ($settings?->allow_messages ?? true),
            'show_email' => $showEmail,
            'account_status' => $this->account_status ?? 'active',
            'role' => $this->role ?? 'user',
            'provider' => $this->provider,
            'posts_count' => array_key_exists('posts_count', $this->resource->getAttributes())
                ? (int) $this->posts_count
                : $this->posts()->count(),
            'followers_count' => array_key_exists('followers_count', $this->resource->getAttributes())
                ? (int) $this->followers_count
                : $this->followers()->count(),
            'following_count' => array_key_exists('following_count', $this->resource->getAttributes())
                ? (int) $this->following_count
                : $this->following()->count(),
            'is_me' => $isMe,
            'is_followed_by_me' => (bool) $isFollowedByMe,
            'has_requested_follow' => $followStatus === 'requested',
            'follow_status' => $followStatus ?? 'not_following',
            'is_blocked_by_me' => (bool) $isBlockedByMe,
            'has_blocked_me' => (bool) $hasBlockedMe,
            'profile_completion' => $this->profileCompletion(),
            'joined_at' => $this->created_at?->toISOString(),
            'last_active_at' => $this->last_active_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }

    private function profileCompletion(): int
    {
        $fields = [
            $this->name,
            $this->username,
            $this->avatar,
            $this->bio,
            $this->cover_image,
            $this->location,
            $this->website,
        ];

        $completed = collect($fields)
            ->filter(fn ($value) => filled($value))
            ->count();

        return (int) round(($completed / count($fields)) * 100);
    }
}
