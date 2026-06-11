<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Follow;
use App\Models\User;
use App\Models\UserBlock;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BlockController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $blockedUsers = $request->user()
            ->blockedUsers()
            ->with('setting')
            ->withCount(['posts', 'followers', 'following'])
            ->latest('user_blocks.created_at')
            ->paginate(Pagination::perPage($request));

        return ApiResponse::paginated(
            'Blocked users fetched successfully',
            'users',
            $blockedUsers,
            UserResource::collection($blockedUsers->items())
        );
    }

    public function store(Request $request, User $user): JsonResponse
    {
        $authUser = $request->user();

        if ($authUser->id === $user->id) {
            return ApiResponse::error('You cannot block yourself.', [], 422);
        }

        $block = UserBlock::query()->firstOrCreate([
            'blocker_id' => $authUser->id,
            'blocked_id' => $user->id,
        ]);

        Follow::query()
            ->where(function ($query) use ($authUser, $user): void {
                $query->where('follower_id', $authUser->id)
                    ->where('following_id', $user->id);
            })
            ->orWhere(function ($query) use ($authUser, $user): void {
                $query->where('follower_id', $user->id)
                    ->where('following_id', $authUser->id);
            })
            ->delete();

        $user->load('setting')->loadCount(['posts', 'followers', 'following']);
        $user->is_followed_by_me = false;
        $user->is_blocked_by_me = true;
        $user->has_blocked_me = $user->hasBlocked($authUser);

        return ApiResponse::success(
            $block->wasRecentlyCreated ? 'User blocked successfully.' : 'User is already blocked.',
            [
                'is_blocked_by_me' => true,
                'has_blocked_me' => (bool) $user->has_blocked_me,
                'user' => UserResource::make($user),
            ],
            $block->wasRecentlyCreated ? 201 : 200
        );
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        UserBlock::query()
            ->where('blocker_id', $request->user()->id)
            ->where('blocked_id', $user->id)
            ->delete();

        $user->load('setting')->loadCount(['posts', 'followers', 'following']);
        $user->is_blocked_by_me = false;
        $user->has_blocked_me = $user->hasBlocked($request->user());

        return ApiResponse::success('User unblocked successfully.', [
            'is_blocked_by_me' => false,
            'has_blocked_me' => (bool) $user->has_blocked_me,
            'user' => UserResource::make($user),
        ]);
    }

    public function status(Request $request, User $user): JsonResponse
    {
        return ApiResponse::success('Block status fetched successfully.', [
            'is_blocked_by_me' => $request->user()->hasBlocked($user),
            'has_blocked_me' => $user->hasBlocked($request->user()),
        ]);
    }
}
