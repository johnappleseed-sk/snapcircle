<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\Post;
use Illuminate\Http\JsonResponse;

class FeedStatusController extends Controller
{
    public function index(): JsonResponse
    {
        $latestPost = Post::query()
            ->latest('id')
            ->first(['id', 'created_at']);

        $unreadNotificationsCount = Notification::query()
            ->where('user_id', request()->user()->id)
            ->whereNull('read_at')
            ->count();

        return ApiResponse::success('Feed status fetched successfully', [
            'latest_post_id' => $latestPost?->id,
            'latest_post_created_at' => $latestPost?->created_at?->toJSON(),
            'total_posts_count' => Post::query()->count(),
            'unread_notifications_count' => $unreadNotificationsCount,
        ]);
    }

    public function comments(Post $post): JsonResponse
    {
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
