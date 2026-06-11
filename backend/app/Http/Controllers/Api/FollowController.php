<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Helpers\ApiResponse;
use App\Http\Resources\UserResource;
use App\Models\Follow;
use App\Models\User;
use App\Services\NotificationService;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FollowController extends Controller
{
    public function __construct(private readonly NotificationService $notifications) {}

    public function store(Request $request, User $user): JsonResponse
    {
        if ($request->user()->id === $user->id) {
            return ApiResponse::error('You cannot follow yourself', [], 422);
        }

        if ($request->user()->isBlockingOrBlockedBy($user)) {
            return ApiResponse::error('You cannot follow this user.', [], 422);
        }

        $follow = Follow::query()->firstOrCreate([
            'follower_id' => $request->user()->id,
            'following_id' => $user->id,
        ]);

        $message = $follow->wasRecentlyCreated
            ? 'User followed successfully'
            : 'User already followed';

        if ($follow->wasRecentlyCreated) {
            $this->notifications->createUserFollowedNotification($request->user(), $user);
        }

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
            ->whereNotIn('users.id', $request->user()->blockedUserIds())
            ->with('setting')
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $request->user()->id),
            ])
            ->latest('follows.created_at')
            ->paginate(Pagination::perPage($request));

        return ApiResponse::paginated(
            'Followers retrieved successfully',
            'users',
            $followers,
            UserResource::collection($followers->items())
        );
    }

    public function following(Request $request, User $user): JsonResponse
    {
        $following = $user->following()
            ->whereNotIn('users.id', $request->user()->blockedUserIds())
            ->with('setting')
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $request->user()->id),
            ])
            ->latest('follows.created_at')
            ->paginate(Pagination::perPage($request));

        return ApiResponse::paginated(
            'Following retrieved successfully',
            'users',
            $following,
            UserResource::collection($following->items())
        );
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
