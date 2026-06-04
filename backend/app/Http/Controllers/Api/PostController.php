<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PostController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $posts = Post::query()
            ->with('user')
            ->withCount(['likes', 'comments'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $request->user()->id),
            ])
            ->when($request->filled('search'), function ($query) use ($request): void {
                $query->where('content', 'like', '%'.$request->string('search')->toString().'%');
            })
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return ApiResponse::success('Posts retrieved', [
            'posts' => PostResource::collection($posts->items()),
            'meta' => [
                'current_page' => $posts->currentPage(),
                'last_page' => $posts->lastPage(),
                'per_page' => $posts->perPage(),
                'total' => $posts->total(),
            ],
            'links' => [
                'first' => $posts->url(1),
                'last' => $posts->url($posts->lastPage()),
                'prev' => $posts->previousPageUrl(),
                'next' => $posts->nextPageUrl(),
            ],
        ]);
    }

    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::query()->create([
            'user_id' => $request->user()->id,
            'content' => $request->input('content'),
            'image_path' => $request->file('image')?->store('posts', 'public'),
        ]);

        $post->load('user')->loadCount(['likes', 'comments']);
        $post->liked_by_me = false;

        return ApiResponse::success('Post created', [
            'post' => PostResource::make($post),
        ], 201);
    }

    public function show(Request $request, Post $post): JsonResponse
    {
        $post->load('user')->loadCount(['likes', 'comments']);
        $post->liked_by_me = $post->likes()
            ->where('user_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('Post retrieved', [
            'post' => PostResource::make($post),
        ]);
    }

    public function update(UpdatePostRequest $request, Post $post): JsonResponse
    {
        if ($post->user_id !== $request->user()->id) {
            return ApiResponse::error('You are not allowed to update this post', [], 403);
        }

        $content = $request->exists('content') ? $request->input('content') : $post->content;
        $imagePath = $post->image_path;

        if ($request->hasFile('image')) {
            if ($post->image_path) {
                Storage::disk('public')->delete($post->image_path);
            }

            $imagePath = $request->file('image')->store('posts', 'public');
        }

        $post->update([
            'content' => $content,
            'image_path' => $imagePath,
        ]);

        $post->load('user')->loadCount(['likes', 'comments']);
        $post->liked_by_me = $post->likes()
            ->where('user_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('Post updated', [
            'post' => PostResource::make($post),
        ]);
    }

    public function destroy(Request $request, Post $post): JsonResponse
    {
        if ($post->user_id !== $request->user()->id) {
            return ApiResponse::error('You are not allowed to delete this post', [], 403);
        }

        $post->delete();

        return ApiResponse::success('Post deleted');
    }
}
