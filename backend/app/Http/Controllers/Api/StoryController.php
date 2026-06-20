<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStoryRequest;
use App\Http\Resources\StoryResource;
use App\Models\Story;
use App\Models\StoryReaction;
use App\Models\User;
use App\Support\Pagination;
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
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $authUser = $request->user();
        $mode = $validated['mode'] ?? 'all';
        $perPage = Pagination::perPage($request, 'stories_per_page');

        $stories = Story::query()
            ->where('expires_at', '>', now())
            ->visibleTo($authUser)
            ->whereNotIn('user_id', $authUser->blockedUserIds())
            ->with('user.setting')
            ->withCount(['views', 'reactions', 'replies'])
            ->withExists([
                'views as viewed_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->withAggregate([
                'reactions as my_reaction' => fn ($query) => $query->where('user_id', $authUser->id),
            ], 'reaction')
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

        $story->load('user.setting')->loadCount(['views', 'reactions', 'replies']);
        $story->viewed_by_me = false;
        $story->my_reaction = null;

        return ApiResponse::success('Story created successfully', [
            'story' => StoryResource::make($story),
        ], 201);
    }

    public function show(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast() || ! $story->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $story->load('user.setting')->loadCount(['views', 'reactions', 'replies']);
        $story->viewed_by_me = $story->views()
            ->where('user_id', $request->user()->id)
            ->exists();
        $story->my_reaction = $story->reactions()
            ->where('user_id', $request->user()->id)
            ->value('reaction');

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
        if ($story->expires_at->isPast() || ! $story->user->canViewPrivateContent($request->user())) {
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

    public function react(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast() || ! $story->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $validated = $request->validate([
            'reaction' => ['required', 'string', 'in:'.implode(',', StoryReaction::ALLOWED_REACTIONS)],
        ]);

        $reaction = $story->reactions()->updateOrCreate(
            ['user_id' => $request->user()->id],
            ['reaction' => $validated['reaction']]
        );

        return ApiResponse::success('Story reaction saved', [
            'story_id' => $story->id,
            'reaction' => $reaction->reaction,
            'reactions_count' => $story->reactions()->count(),
        ]);
    }

    public function removeReaction(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast() || ! $story->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $story->reactions()
            ->where('user_id', $request->user()->id)
            ->delete();

        return ApiResponse::success('Story reaction removed', [
            'story_id' => $story->id,
            'reaction' => null,
            'reactions_count' => $story->reactions()->count(),
        ]);
    }

    public function reply(Request $request, Story $story): JsonResponse
    {
        if ($story->expires_at->isPast() || ! $story->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('Story not found or expired', [], 404);
        }

        $validated = $request->validate([
            'message' => ['required', 'string', 'max:500'],
        ]);

        $reply = $story->replies()->create([
            'user_id' => $request->user()->id,
            'message' => trim($validated['message']),
        ]);

        return ApiResponse::success('Story reply sent', [
            'story_id' => $story->id,
            'reply_id' => $reply->id,
            'replies_count' => $story->replies()->count(),
        ], 201);
    }

    public function userStories(Request $request, User $user): JsonResponse
    {
        $perPage = Pagination::perPage($request, 'stories_per_page');

        $stories = $user->stories()
            ->where('expires_at', '>', now())
            ->with('user.setting')
            ->withCount(['views', 'reactions', 'replies'])
            ->withExists([
                'views as viewed_by_me' => fn ($query) => $query->where('user_id', $request->user()->id),
            ])
            ->withAggregate([
                'reactions as my_reaction' => fn ($query) => $query->where('user_id', $request->user()->id),
            ], 'reaction')
            ->latest()
            ->when(! $user->canViewPrivateContent($request->user()), fn ($query) => $query->whereRaw('1 = 0'))
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
