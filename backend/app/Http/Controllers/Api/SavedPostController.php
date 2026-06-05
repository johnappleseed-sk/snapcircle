<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Models\Post;
use App\Models\SavedPost;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SavedPostController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ]);

        $perPage = (int) ($validated['per_page'] ?? 10);
        $authUser = $request->user();

        $savedPosts = Post::query()
            ->whereHas('savedPosts', fn ($query) => $query->where('user_id', $authUser->id))
            ->with('user')
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->orderByDesc(
                SavedPost::query()
                    ->select('created_at')
                    ->whereColumn('saved_posts.post_id', 'posts.id')
                    ->where('user_id', $authUser->id)
                    ->limit(1)
            )
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::success('Saved posts fetched successfully', [
            'data' => PostResource::collection($savedPosts->items()),
            'current_page' => $savedPosts->currentPage(),
            'last_page' => $savedPosts->lastPage(),
            'per_page' => $savedPosts->perPage(),
            'total' => $savedPosts->total(),
        ]);
    }

    public function store(Request $request, Post $post): JsonResponse
    {
        $savedPost = SavedPost::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'post_id' => $post->id,
        ]);

        $message = $savedPost->wasRecentlyCreated
            ? 'Post saved successfully'
            : 'Post already saved';

        return ApiResponse::success($message, [
            'post_id' => $post->id,
            'saved_by_me' => true,
            'saves_count' => $post->savedPosts()->count(),
        ]);
    }

    public function destroy(Request $request, Post $post): JsonResponse
    {
        $deleted = SavedPost::query()
            ->where('user_id', $request->user()->id)
            ->where('post_id', $post->id)
            ->delete();

        $message = $deleted
            ? 'Post removed from saved posts'
            : 'Post was not saved';

        return ApiResponse::success($message, [
            'post_id' => $post->id,
            'saved_by_me' => false,
            'saves_count' => $post->savedPosts()->count(),
        ]);
    }
}
