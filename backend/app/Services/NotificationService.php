<?php

namespace App\Services;

use App\Models\Comment;
use App\Models\Notification;
use App\Models\Post;
use App\Models\User;
use Throwable;

class NotificationService
{
    public function createPostLikedNotification(User $actor, Post $post): void
    {
        if ($actor->id === $post->user_id) {
            return;
        }

        $this->safeCreate(function () use ($actor, $post): void {
            Notification::query()->firstOrCreate([
                'user_id' => $post->user_id,
                'actor_id' => $actor->id,
                'type' => Notification::TYPE_POST_LIKED,
                'post_id' => $post->id,
                'read_at' => null,
            ], [
                'data' => [
                    'actor_name' => $actor->name,
                    'post_preview' => $this->preview($post->content),
                ],
            ]);
        });
    }

    public function createPostCommentedNotification(User $actor, Post $post, Comment $comment): void
    {
        if ($actor->id === $post->user_id) {
            return;
        }

        $this->safeCreate(function () use ($actor, $post, $comment): void {
            Notification::query()->create([
                'user_id' => $post->user_id,
                'actor_id' => $actor->id,
                'type' => Notification::TYPE_POST_COMMENTED,
                'post_id' => $post->id,
                'comment_id' => $comment->id,
                'data' => [
                    'actor_name' => $actor->name,
                    'post_preview' => $this->preview($post->content),
                    'comment_preview' => $this->preview($comment->comment),
                ],
            ]);
        });
    }

    public function createUserFollowedNotification(User $actor, User $followedUser): void
    {
        if ($actor->id === $followedUser->id) {
            return;
        }

        $this->safeCreate(function () use ($actor, $followedUser): void {
            Notification::query()->firstOrCreate([
                'user_id' => $followedUser->id,
                'actor_id' => $actor->id,
                'type' => Notification::TYPE_USER_FOLLOWED,
                'read_at' => null,
            ], [
                'data' => [
                    'actor_name' => $actor->name,
                ],
            ]);
        });
    }

    public function createFollowRequestedNotification(User $actor, User $requestedUser): void
    {
        if ($actor->id === $requestedUser->id) {
            return;
        }

        $this->safeCreate(function () use ($actor, $requestedUser): void {
            Notification::query()->firstOrCreate([
                'user_id' => $requestedUser->id,
                'actor_id' => $actor->id,
                'type' => Notification::TYPE_FOLLOW_REQUESTED,
                'read_at' => null,
            ], [
                'data' => [
                    'actor_name' => $actor->name,
                ],
            ]);
        });
    }

    public function createFollowRequestApprovedNotification(User $owner, User $follower): void
    {
        if ($owner->id === $follower->id) {
            return;
        }

        $this->safeCreate(function () use ($owner, $follower): void {
            Notification::query()->create([
                'user_id' => $follower->id,
                'actor_id' => $owner->id,
                'type' => Notification::TYPE_FOLLOW_REQUEST_APPROVED,
                'data' => [
                    'actor_name' => $owner->name,
                ],
            ]);
        });
    }

    private function preview(?string $value): ?string
    {
        if (! $value) {
            return null;
        }

        return mb_substr($value, 0, 120);
    }

    private function safeCreate(callable $callback): void
    {
        try {
            $callback();
        } catch (Throwable) {
            // Notification failures should not block the user action.
        }
    }
}
