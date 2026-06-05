<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Helpers\ApiResponse;
use App\Models\Like;
use App\Models\Post;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LikeController extends Controller
{
    public function __construct(private readonly NotificationService $notifications) {}

    public function store(Request $request, Post $post): JsonResponse
    {
        $like = Like::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'post_id' => $post->id,
        ]);

        $message = $like->wasRecentlyCreated
            ? 'Post liked successfully'
            : 'Post already liked';

        if ($like->wasRecentlyCreated) {
            $this->notifications->createPostLikedNotification($request->user(), $post);
        }

        return ApiResponse::success($message, [
            'likes_count' => $post->likes()->count(),
            'liked_by_me' => true,
        ]);
    }

    public function destroy(Request $request, Post $post): JsonResponse
    {
        $deleted = Like::query()
            ->where('user_id', $request->user()->id)
            ->where('post_id', $post->id)
            ->delete();

        $message = $deleted
            ? 'Post unliked successfully'
            : 'Post not liked yet';

        return ApiResponse::success($message, [
            'likes_count' => $post->likes()->count(),
            'liked_by_me' => false,
        ]);
    }
}
