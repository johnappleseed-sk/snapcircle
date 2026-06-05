<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStoryRequest;
use App\Http\Resources\StoryResource;
use App\Models\Story;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class StoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'mode' => ['sometimes', 'string', 'in:all,following,mine'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ]);

        $authUser = $request->user();
        $mode = $validated['mode'] ?? 'all';
        $perPage = (int) ($validated['per_page'] ?? 15);

        $stories = Story::query()
            ->where('expires_at', '>', now())
            ->with('user')
            ->withCount('views')
            ->withExists([
                'views as viewed_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->when($mode === 'following', function ($query) use ($authUser): void {
                $followingIds = $authUser->following()->pluck('users.id')->push($authUser->id);
                $query->whereIn('user_id', $followingIds);
            })
            ->when($mode === 'mine', fn ($query) => $query->where('user_id', $authUser->id))
            ->latest()
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::success('Stories fetched successfully', [
            'data' => StoryResource::collection($stories->items()),
            'current_page' => $stories->currentPage(),
            'last_page' => $stories->lastPage(),
            'per_page' => $stories->perPage(),
            'total' => $stories->total(),
        ]);
    }

    public function store(StoreStoryRequest $request): JsonResponse
    {
        $story = Story::query()->create([
            'user_id' => $request->user()->id,
            'media_path' => $request->file('media')->store('stories', 'public'),
            'caption' => $request->input('caption'),
            'expires_at' => now()->addDay(),
        ]);

        $story->load('user')->loadCount('views');
        $story->viewed_by_me = false;

        return ApiResponse::success('Story created successfully', [
            'story' => StoryResource::make($story),
        ], 201);
    }

    public function show(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast()) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $story->load('user')->loadCount('views');
        $story->viewed_by_me = $story->views()
            ->where('user_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('Story fetched successfully', [
            'story' => StoryResource::make($story),
        ]);
    }

    public function destroy(Request $request, Story $story): JsonResponse
    {
        $this->authorize('delete', $story);

        if ($story->media_path && ! str_starts_with($story->media_path, 'http')) {
            // Story media is deleted only when it is a local public-disk path.
            Storage::disk('public')->delete($story->media_path);
        }

        $story->delete();

        return ApiResponse::success('Story deleted successfully');
    }

    public function markAsViewed(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast()) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $story->views()->firstOrCreate([
            'user_id' => $request->user()->id,
        ]);

        return ApiResponse::success('Story marked as viewed', [
            'story_id' => $story->id,
            'viewed_by_me' => true,
            'views_count' => $story->views()->count(),
        ]);
    }

    public function userStories(Request $request, User $user): JsonResponse
    {
        $perPage = min((int) $request->integer('per_page', 15), 50);

        $stories = $user->stories()
            ->where('expires_at', '>', now())
            ->with('user')
            ->withCount('views')
            ->withExists([
                'views as viewed_by_me' => fn ($query) => $query->where('user_id', $request->user()->id),
            ])
            ->latest()
            ->paginate($perPage);

        return ApiResponse::success('User stories fetched successfully', [
            'data' => StoryResource::collection($stories->items()),
            'current_page' => $stories->currentPage(),
            'last_page' => $stories->lastPage(),
            'per_page' => $stories->perPage(),
            'total' => $stories->total(),
        ]);
    }
}
