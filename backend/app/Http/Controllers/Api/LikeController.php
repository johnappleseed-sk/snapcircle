<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Like;
use App\Models\Post;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LikeController extends Controller
{
    public function store(Request $request, Post $post): JsonResponse
    {
        $like = Like::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'post_id' => $post->id,
        ]);

        $message = $like->wasRecentlyCreated
            ? 'Post liked successfully'
            : 'Post already liked';

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
