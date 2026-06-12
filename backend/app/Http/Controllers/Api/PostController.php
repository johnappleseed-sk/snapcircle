<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use App\Models\PostMedia;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
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
        $blockedUserIds = $authUser->blockedUserIds();

        $posts = Post::query()
            ->with(['user.setting', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->whereNotIn('user_id', $blockedUserIds)
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
        $post = DB::transaction(function () use ($request): Post {
            $mediaPaths = $this->storeUploadedMedia($request);

            $post = Post::query()->create([
                'user_id' => $request->user()->id,
                'content' => $request->input('content'),
                'image_path' => $mediaPaths[0] ?? null,
            ]);

            $this->syncMediaRecords($post, $mediaPaths);

            return $post;
        });

        $post->load(['user.setting', 'media'])->loadCount(['likes', 'comments', 'savedPosts']);
        $post->liked_by_me = false;
        $post->saved_by_me = false;

        return ApiResponse::success('Post created', [
            'post' => PostResource::make($post),
        ], 201);
    }

    public function show(Request $request, Post $post): JsonResponse
    {
        if ($request->user()->isBlockingOrBlockedBy($post->user)) {
            return ApiResponse::error('This post is not available.', [], 404);
        }

        $post->load(['user.setting', 'media'])->loadCount(['likes', 'comments', 'savedPosts']);
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

        DB::transaction(function () use ($request, $post): void {
            $content = $request->exists('content') ? $request->input('content') : $post->content;
            $imagePath = $post->image_path;

            if ($request->hasFile('image') || $request->hasFile('images')) {
                $this->deleteStoredMedia($post);
                $mediaPaths = $this->storeUploadedMedia($request);
                $imagePath = $mediaPaths[0] ?? null;
                $this->syncMediaRecords($post, $mediaPaths);
            }

            $post->update([
                'content' => $content,
                'image_path' => $imagePath,
            ]);
        });

        $post->load(['user.setting', 'media'])->loadCount(['likes', 'comments', 'savedPosts']);
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

        $this->deleteStoredMedia($post);
        $post->delete();

        return ApiResponse::success('Post deleted');
    }

    /**
     * @return list<string>
     */
    private function storeUploadedMedia(Request $request): array
    {
        return collect($this->uploadedImages($request))
            ->map(fn (UploadedFile $file): string => $file->store('posts', 'public'))
            ->values()
            ->all();
    }

    /**
     * @return list<UploadedFile>
     */
    private function uploadedImages(Request $request): array
    {
        $files = [];

        if ($request->hasFile('images')) {
            $images = $request->file('images');
            $files = is_array($images) ? $images : [$images];
        }

        if ($request->hasFile('image')) {
            $files[] = $request->file('image');
        }

        return array_values(array_filter($files, fn ($file): bool => $file instanceof UploadedFile));
    }

    /**
     * @param  list<string>  $mediaPaths
     */
    private function syncMediaRecords(Post $post, array $mediaPaths): void
    {
        foreach ($mediaPaths as $index => $path) {
            PostMedia::query()->create([
                'post_id' => $post->id,
                'path' => $path,
                'type' => 'image',
                'sort_order' => $index,
            ]);
        }
    }

    private function deleteStoredMedia(Post $post): void
    {
        $paths = $post->media()->pluck('path')
            ->when($post->image_path, fn ($collection) => $collection->push($post->image_path))
            ->filter(fn (?string $path): bool => filled($path) && ! str_starts_with($path, 'http'))
            ->unique()
            ->values();

        Storage::disk('public')->delete($paths->all());
        $post->media()->delete();
    }
}
