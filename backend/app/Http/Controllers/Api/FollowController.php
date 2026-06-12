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

        $status = $user->is_private ? Follow::STATUS_PENDING : Follow::STATUS_ACCEPTED;
        $follow = Follow::query()->firstOrCreate([
            'follower_id' => $request->user()->id,
            'following_id' => $user->id,
        ], [
            'status' => $status,
        ]);
        $previousStatus = $follow->status;
        $statusChanged = false;

        if (! $follow->wasRecentlyCreated && $follow->status !== $status && $follow->status !== Follow::STATUS_ACCEPTED) {
            $follow->update(['status' => $status]);
            $follow->refresh();
            $statusChanged = $previousStatus !== $follow->status;
        }

        $message = match ($follow->status) {
            Follow::STATUS_PENDING => $follow->wasRecentlyCreated
                ? 'Follow request sent'
                : 'Follow request already sent',
            default => $follow->wasRecentlyCreated || $statusChanged
                ? 'User followed successfully'
                : 'User already followed',
        };

        if (($follow->wasRecentlyCreated || $statusChanged) && $follow->status === Follow::STATUS_ACCEPTED) {
            $this->notifications->createUserFollowedNotification($request->user(), $user);
        }

        if ($follow->wasRecentlyCreated && $follow->status === Follow::STATUS_PENDING) {
            $this->notifications->createFollowRequestedNotification($request->user(), $user);
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
            ? 'Follow removed successfully'
            : 'User not followed yet';

        return ApiResponse::success($message, $this->followStatus($request, $user));
    }

    public function requests(Request $request): JsonResponse
    {
        $followRequests = Follow::query()
            ->where('following_id', $request->user()->id)
            ->where('status', Follow::STATUS_PENDING)
            ->whereNotIn('follower_id', $request->user()->blockedUserIds())
            ->with(['follower.setting'])
            ->latest()
            ->paginate(Pagination::perPage($request));

        $users = collect($followRequests->items())
            ->map(function (Follow $follow) {
                $user = $follow->follower;
                $user->follow_status = 'requested';

                return $user;
            });

        return ApiResponse::paginated(
            'Follow requests retrieved successfully',
            'users',
            $followRequests,
            UserResource::collection($users)
        );
    }

    public function approve(Request $request, User $user): JsonResponse
    {
        $follow = Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $request->user()->id)
            ->where('status', Follow::STATUS_PENDING)
            ->first();

        if (! $follow) {
            return ApiResponse::error('Follow request not found.', [], 404);
        }

        if ($request->user()->isBlockingOrBlockedBy($user)) {
            $follow->delete();

            return ApiResponse::error('This follow request is not available.', [], 422);
        }

        $follow->update(['status' => Follow::STATUS_ACCEPTED]);
        $this->notifications->createFollowRequestApprovedNotification($request->user(), $user);

        return ApiResponse::success('Follow request approved.', [
            'requester' => UserResource::make($user->fresh(['setting'])->loadCount(['posts', 'followers', 'following'])),
            'followers_count' => $request->user()->followers()->count(),
        ]);
    }

    public function reject(Request $request, User $user): JsonResponse
    {
        $deleted = Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $request->user()->id)
            ->where('status', Follow::STATUS_PENDING)
            ->delete();

        return ApiResponse::success($deleted ? 'Follow request rejected.' : 'Follow request not found.', [
            'followers_count' => $request->user()->followers()->count(),
        ]);
    }

    public function removeFollower(Request $request, User $user): JsonResponse
    {
        $deleted = Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $request->user()->id)
            ->where('status', Follow::STATUS_ACCEPTED)
            ->delete();

        return ApiResponse::success($deleted ? 'Follower removed.' : 'Follower not found.', [
            'followers_count' => $request->user()->followers()->count(),
        ]);
    }

    public function followers(Request $request, User $user): JsonResponse
    {
        if (! $user->canViewPrivateContent($request->user())) {
            return $this->emptyUsersPage('Followers retrieved successfully');
        }

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
        if (! $user->canViewPrivateContent($request->user())) {
            return $this->emptyUsersPage('Following retrieved successfully');
        }

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
        $status = $this->currentFollowStatus($request, $user);

        return [
            'followers_count' => $user->followers()->count(),
            'following_count' => $request->user()->following()->count(),
            'is_followed_by_me' => $status === Follow::STATUS_ACCEPTED,
            'has_requested_follow' => $status === Follow::STATUS_PENDING,
            'follow_status' => match ($status) {
                Follow::STATUS_ACCEPTED => 'following',
                Follow::STATUS_PENDING => 'requested',
                default => 'not_following',
            },
        ];
    }

    private function currentFollowStatus(Request $request, User $user): ?string
    {
        return Follow::query()
            ->where('follower_id', $request->user()->id)
            ->where('following_id', $user->id)
            ->value('status');
    }

    private function emptyUsersPage(string $message): JsonResponse
    {
        return ApiResponse::success($message, [
            'users' => [],
            'meta' => [
                'current_page' => 1,
                'last_page' => 1,
                'per_page' => 0,
                'total' => 0,
            ],
            'links' => [
                'first' => null,
                'last' => null,
                'prev' => null,
                'next' => null,
            ],
        ]);
    }
}
