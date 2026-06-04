<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Follow;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FollowController extends Controller
{
    public function store(Request $request, User $user): JsonResponse
    {
        if ($request->user()->id === $user->id) {
            return ApiResponse::error('You cannot follow yourself', [], 422);
        }

        $follow = Follow::query()->firstOrCreate([
            'follower_id' => $request->user()->id,
            'following_id' => $user->id,
        ]);

        $message = $follow->wasRecentlyCreated
            ? 'User followed successfully'
            : 'User already followed';

        return ApiResponse::success($message, $this->followStatus($request, $user));
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        $deleted = Follow::query()
            ->where('follower_id', $request->user()->id)
            ->where('following_id', $user->id)
            ->delete();

        $message = $deleted
            ? 'User unfollowed successfully'
            : 'User not followed yet';

        return ApiResponse::success($message, $this->followStatus($request, $user));
    }

    public function followers(Request $request, User $user): JsonResponse
    {
        $followers = $user->followers()
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $request->user()->id),
            ])
            ->latest('follows.created_at')
            ->paginate(10);

        return ApiResponse::success('Followers retrieved successfully', [
            'users' => UserResource::collection($followers->items()),
            'meta' => [
                'current_page' => $followers->currentPage(),
                'last_page' => $followers->lastPage(),
                'per_page' => $followers->perPage(),
                'total' => $followers->total(),
            ],
            'links' => [
                'first' => $followers->url(1),
                'last' => $followers->url($followers->lastPage()),
                'prev' => $followers->previousPageUrl(),
                'next' => $followers->nextPageUrl(),
            ],
        ]);
    }

    public function following(Request $request, User $user): JsonResponse
    {
        $following = $user->following()
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $request->user()->id),
            ])
            ->latest('follows.created_at')
            ->paginate(10);

        return ApiResponse::success('Following retrieved successfully', [
            'users' => UserResource::collection($following->items()),
            'meta' => [
                'current_page' => $following->currentPage(),
                'last_page' => $following->lastPage(),
                'per_page' => $following->perPage(),
                'total' => $following->total(),
            ],
            'links' => [
                'first' => $following->url(1),
                'last' => $following->url($following->lastPage()),
                'prev' => $following->previousPageUrl(),
                'next' => $following->nextPageUrl(),
            ],
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function followStatus(Request $request, User $user): array
    {
        return [
            'followers_count' => $user->followers()->count(),
            'following_count' => $request->user()->following()->count(),
            'is_followed_by_me' => $user->followers()
                ->where('follower_id', $request->user()->id)
                ->exists(),
        ];
    }
}
