<?php

namespace App\Services;

use App\Models\Comment;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Post;
use App\Models\User;
use Throwable;

class NotificationService
{
    public function __construct(private readonly PushNotificationService $pushNotifications)
    {
    }

    public function createPostLikedNotification(User $actor, Post $post): void
    {
        $postOwner = $post->user;

        if (! $postOwner || $actor->id === $post->user_id || $actor->isBlockingOrBlockedBy($postOwner)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($actor, $post): Notification {
            return Notification::query()->firstOrCreate([
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

        if ($notification?->wasRecentlyCreated) {
            $this->pushNotifications->sendToUser(
                $postOwner,
                'New like',
                "{$actor->name} liked your post.",
                'like',
                [
                    'post_id' => $post->id,
                    'user_id' => $actor->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    public function createPostCommentedNotification(User $actor, Post $post, Comment $comment): void
    {
        $postOwner = $post->user;

        if (! $postOwner || $actor->id === $post->user_id || $actor->isBlockingOrBlockedBy($postOwner)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($actor, $post, $comment): Notification {
            return Notification::query()->create([
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

        if ($notification) {
            $this->pushNotifications->sendToUser(
                $postOwner,
                'New comment',
                "{$actor->name} commented on your post.",
                'comment',
                [
                    'post_id' => $post->id,
                    'comment_id' => $comment->id,
                    'user_id' => $actor->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    public function createUserFollowedNotification(User $actor, User $followedUser): void
    {
        if ($actor->id === $followedUser->id || $actor->isBlockingOrBlockedBy($followedUser)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($actor, $followedUser): Notification {
            return Notification::query()->firstOrCreate([
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

        if ($notification?->wasRecentlyCreated) {
            $this->pushNotifications->sendToUser(
                $followedUser,
                'New follower',
                "{$actor->name} started following you.",
                'follow',
                [
                    'user_id' => $actor->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    public function createFollowRequestedNotification(User $actor, User $requestedUser): void
    {
        if ($actor->id === $requestedUser->id || $actor->isBlockingOrBlockedBy($requestedUser)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($actor, $requestedUser): Notification {
            return Notification::query()->firstOrCreate([
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

        if ($notification?->wasRecentlyCreated) {
            $this->pushNotifications->sendToUser(
                $requestedUser,
                'New follow request',
                "{$actor->name} requested to follow you.",
                'follow_request',
                [
                    'user_id' => $actor->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    public function createFollowRequestApprovedNotification(User $owner, User $follower): void
    {
        if ($owner->id === $follower->id || $owner->isBlockingOrBlockedBy($follower)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($owner, $follower): Notification {
            return Notification::query()->create([
                'user_id' => $follower->id,
                'actor_id' => $owner->id,
                'type' => Notification::TYPE_FOLLOW_REQUEST_APPROVED,
                'data' => [
                    'actor_name' => $owner->name,
                ],
            ]);
        });

        if ($notification) {
            $this->pushNotifications->sendToUser(
                $follower,
                'Follow request approved',
                "{$owner->name} approved your follow request.",
                'follow_request_approved',
                [
                    'user_id' => $owner->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    public function createMessageSentNotification(User $actor, User $recipient, Message $message): void
    {
        if ($actor->id === $recipient->id || $actor->isBlockingOrBlockedBy($recipient)) {
            return;
        }

        $notification = $this->safeCreate(function () use ($actor, $recipient, $message): Notification {
            return Notification::query()->create([
                'user_id' => $recipient->id,
                'actor_id' => $actor->id,
                'type' => Notification::TYPE_MESSAGE_SENT,
                'data' => [
                    'actor_name' => $actor->name,
                    'conversation_id' => $message->conversation_id,
                    'message_id' => $message->id,
                    'message_preview' => $this->preview($message->message),
                ],
            ]);
        });

        if ($notification) {
            $this->pushNotifications->sendToUser(
                $recipient,
                'New message',
                "{$actor->name} sent you a message.",
                'message',
                [
                    'conversation_id' => $message->conversation_id,
                    'message_id' => $message->id,
                    'user_id' => $actor->id,
                    'notification_id' => $notification->id,
                ]
            );
        }
    }

    private function preview(?string $value): ?string
    {
        if (! $value) {
            return null;
        }

        return mb_substr($value, 0, 120);
    }

    private function safeCreate(callable $callback): mixed
    {
        try {
            return $callback();
        } catch (Throwable) {
            // Notification failures should not block the user action.
            return null;
        }
    }
}
