<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Http\Resources\UserResource;
use App\Models\Comment;
use App\Models\Follow;
use App\Models\Post;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'limit' => ['sometimes', 'integer', 'min:1', 'max:30'],
        ]);

        $limit = Pagination::perPage($request);
        $user = $request->user();

        return ApiResponse::success('Activity fetched successfully', [
            'posts' => PostResource::collection($this->postQuery($request)
                ->where('user_id', $user->id)
                ->latest()
                ->limit($limit)
                ->get()),
            'comments' => $this->recentComments($request, $limit),
            'likes' => PostResource::collection($this->postQuery($request)
                ->whereHas('likes', fn ($query) => $query->where('user_id', $user->id))
                ->orderByDesc(
                    \App\Models\Like::query()
                        ->select('created_at')
                        ->whereColumn('likes.post_id', 'posts.id')
                        ->where('user_id', $user->id)
                        ->limit(1)
                )
                ->limit($limit)
                ->get()),
            'saved' => PostResource::collection($this->postQuery($request)
                ->whereHas('savedPosts', fn ($query) => $query->where('user_id', $user->id))
                ->orderByDesc(
                    \App\Models\SavedPost::query()
                        ->select('created_at')
                        ->whereColumn('saved_posts.post_id', 'posts.id')
                        ->where('user_id', $user->id)
                        ->limit(1)
                )
                ->limit($limit)
                ->get()),
            'follows' => $this->recentFollows($request, $limit),
        ]);
    }

    private function postQuery(Request $request)
    {
        $authUser = $request->user();

        return Post::query()
            ->visibleTo($authUser)
            ->whereNotIn('user_id', $authUser->blockedUserIds())
            ->with(['user.setting', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ]);
    }

    private function recentComments(Request $request, int $limit): array
    {
        return Comment::query()
            ->where('user_id', $request->user()->id)
            ->whereHas('post', fn ($query) => $query->visibleTo($request->user()))
            ->with(['post.user.setting', 'post.media'])
            ->latest()
            ->limit($limit)
            ->get()
            ->map(fn (Comment $comment): array => [
                'id' => $comment->id,
                'comment' => $comment->comment,
                'created_at' => optional($comment->created_at)->toISOString(),
                'post' => $comment->post ? PostResource::make($comment->post) : null,
            ])
            ->all();
    }

    private function recentFollows(Request $request, int $limit): array
    {
        return Follow::query()
            ->where('follower_id', $request->user()->id)
            ->where('status', Follow::STATUS_ACCEPTED)
            ->with('following.setting')
            ->latest()
            ->limit($limit)
            ->get()
            ->map(fn (Follow $follow): array => [
                'id' => $follow->id,
                'created_at' => optional($follow->created_at)->toISOString(),
                'user' => $follow->following ? UserResource::make($follow->following) : null,
            ])
            ->all();
    }
}
