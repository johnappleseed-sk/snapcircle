<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Http\Resources\SavedCollectionResource;
use App\Models\Post;
use App\Models\SavedCollection;
use App\Models\SavedPost;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SavedCollectionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $collections = SavedCollection::query()
            ->where('user_id', $request->user()->id)
            ->withCount('posts')
            ->with(['posts' => fn ($query) => $this->decoratePostQuery($query, $request)->limit(1)])
            ->latest('updated_at')
            ->get();

        return ApiResponse::success('Saved collections fetched successfully', [
            'data' => SavedCollectionResource::collection($collections),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'min:1', 'max:80'],
        ]);

        $collection = SavedCollection::query()->create([
            'user_id' => $request->user()->id,
            'name' => trim($validated['name']),
        ]);

        return ApiResponse::success('Saved collection created successfully', [
            'collection' => SavedCollectionResource::make($collection->loadCount('posts')),
        ], 201);
    }

    public function update(Request $request, SavedCollection $collection): JsonResponse
    {
        $this->authorizeCollection($request, $collection);

        $validated = $request->validate([
            'name' => ['required', 'string', 'min:1', 'max:80'],
        ]);

        $collection->update(['name' => trim($validated['name'])]);

        return ApiResponse::success('Saved collection renamed successfully', [
            'collection' => SavedCollectionResource::make($collection->fresh()->loadCount('posts')),
        ]);
    }

    public function destroy(Request $request, SavedCollection $collection): JsonResponse
    {
        $this->authorizeCollection($request, $collection);

        $collection->delete();

        return ApiResponse::success('Saved collection deleted successfully');
    }

    public function addPost(Request $request, SavedCollection $collection, Post $post): JsonResponse
    {
        $this->authorizeCollection($request, $collection);

        if (! $post->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('This post is not available.', [], 404);
        }

        SavedPost::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'post_id' => $post->id,
        ]);

        $collection->posts()->syncWithoutDetaching([$post->id]);
        $collection->touch();

        return ApiResponse::success('Post added to collection successfully', [
            'collection' => SavedCollectionResource::make($collection->fresh()->loadCount('posts')),
        ]);
    }

    public function removePost(Request $request, SavedCollection $collection, Post $post): JsonResponse
    {
        $this->authorizeCollection($request, $collection);

        $collection->posts()->detach($post->id);
        $collection->touch();

        return ApiResponse::success('Post removed from collection successfully', [
            'collection' => SavedCollectionResource::make($collection->fresh()->loadCount('posts')),
        ]);
    }

    public function posts(Request $request, SavedCollection $collection): JsonResponse
    {
        $this->authorizeCollection($request, $collection);

        $posts = $collection->posts()
            ->wherePivotNotNull('created_at')
            ->whereNotIn('posts.user_id', $request->user()->blockedUserIds())
            ->visibleTo($request->user());

        $this->decoratePostQuery($posts, $request);

        $paginated = $posts->paginate(Pagination::perPage($request))->withQueryString();

        return ApiResponse::success('Saved collection posts fetched successfully', [
            'data' => PostResource::collection($paginated->items()),
            'current_page' => $paginated->currentPage(),
            'last_page' => $paginated->lastPage(),
            'per_page' => $paginated->perPage(),
            'total' => $paginated->total(),
        ]);
    }

    private function authorizeCollection(Request $request, SavedCollection $collection): void
    {
        abort_if($collection->user_id !== $request->user()->id, 404);
    }

    private function decoratePostQuery($query, Request $request)
    {
        $authUser = $request->user();

        return $query
            ->with(['user.setting', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ]);
    }
}
