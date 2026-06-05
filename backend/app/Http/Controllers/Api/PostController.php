<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PostController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'mode' => ['sometimes', 'string', 'in:all,following,popular,mine'],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $mode = $validated['mode'] ?? 'all';
        $perPage = Pagination::perPage($request);
        $authUser = $request->user();

        $posts = Post::query()
            ->with('user.setting')
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->when($mode === 'following', function ($query) use ($authUser): void {
                $followingIds = $authUser->following()->pluck('users.id')->push($authUser->id);

                $query->whereIn('user_id', $followingIds);
            })
            ->when($mode === 'mine', function ($query) use ($authUser): void {
                $query->where('user_id', $authUser->id);
            })
            ->when($request->filled('search'), function ($query) use ($request): void {
                $query->where('content', 'like', '%'.$request->string('search')->toString().'%');
            })
            ->when(
                $mode === 'popular',
                fn ($query) => $query
                    ->orderByDesc('likes_count')
                    ->orderByDesc('comments_count')
                    ->latest(),
                fn ($query) => $query->latest()
            )
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::success('Posts fetched successfully', [
            'data' => PostResource::collection($posts->items()),
            'current_page' => $posts->currentPage(),
            'last_page' => $posts->lastPage(),
            'per_page' => $posts->perPage(),
            'total' => $posts->total(),
        ]);
    }

    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::query()->create([
            'user_id' => $request->user()->id,
            'content' => $request->input('content'),
            'image_path' => $request->file('image')?->store('posts', 'public'),
        ]);

        $post->load('user.setting')->loadCount(['likes', 'comments', 'savedPosts']);
        $post->liked_by_me = false;
        $post->saved_by_me = false;

        return ApiResponse::success('Post created', [
            'post' => PostResource::make($post),
        ], 201);
    }

    public function show(Request $request, Post $post): JsonResponse
    {
        $post->load('user.setting')->loadCount(['likes', 'comments', 'savedPosts']);
        $post->liked_by_me = $post->likes()
            ->where('user_id', $request->user()->id)
            ->exists();
        $post->saved_by_me = $post->savedPosts()
            ->where('user_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('Post fetched successfully', [
            'post' => PostResource::make($post),
        ]);
    }

    public function update(UpdatePostRequest $request, Post $post): JsonResponse
    {
        $this->authorize('update', $post);

        $content = $request->exists('content') ? $request->input('content') : $post->content;
        $imagePath = $post->image_path;

        if ($request->hasFile('image')) {
            if ($post->image_path) {
                // Post images are stored locally in the public disk; external URLs are never deleted.
                Storage::disk('public')->delete($post->image_path);
            }

            $imagePath = $request->file('image')->store('posts', 'public');
        }

        $post->update([
            'content' => $content,
            'image_path' => $imagePath,
        ]);

        $post->load('user.setting')->loadCount(['likes', 'comments', 'savedPosts']);
        $post->liked_by_me = $post->likes()
            ->where('user_id', $request->user()->id)
            ->exists();
        $post->saved_by_me = $post->savedPosts()
            ->where('user_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('Post updated', [
            'post' => PostResource::make($post),
        ]);
    }

    public function destroy(Request $request, Post $post): JsonResponse
    {
        $this->authorize('delete', $post);

        $post->delete();

        return ApiResponse::success('Post deleted');
    }
}
