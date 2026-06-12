<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeedStatusController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $latestPost = Post::query()
            ->visibleTo($request->user())
            ->whereNotIn('user_id', $request->user()->blockedUserIds())
            ->latest('id')
            ->first(['id', 'created_at']);

        $unreadNotificationsCount = Notification::query()
            ->where('user_id', request()->user()->id)
            ->whereNull('read_at')
            ->count();

        return ApiResponse::success('Feed status fetched successfully', [
            'latest_post_id' => $latestPost?->id,
            'latest_post_created_at' => $latestPost?->created_at?->toJSON(),
            'total_posts_count' => Post::query()
                ->visibleTo($request->user())
                ->whereNotIn('user_id', $request->user()->blockedUserIds())
                ->count(),
            'unread_notifications_count' => $unreadNotificationsCount,
        ]);
    }

    public function comments(Post $post): JsonResponse
    {
        if (! $post->user->canViewPrivateContent(request()->user())) {
            return ApiResponse::error('This post is not available.', [], 404);
        }

        $latestComment = $post->comments()
            ->latest('id')
            ->first(['id', 'created_at']);

        return ApiResponse::success('Comments status fetched successfully', [
            'post_id' => $post->id,
            'latest_comment_id' => $latestComment?->id,
            'latest_comment_created_at' => $latestComment?->created_at?->toJSON(),
            'comments_count' => $post->comments()->count(),
        ]);
    }
}
