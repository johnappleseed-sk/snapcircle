<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCommentRequest;
use App\Http\Requests\UpdateCommentRequest;
use App\Http\Resources\CommentResource;
use App\Models\Comment;
use App\Models\Post;
use App\Services\NotificationService;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function __construct(private readonly NotificationService $notifications) {}

    public function index(Request $request, Post $post): JsonResponse
    {
        if (! $post->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('This post is not available.', [], 404);
        }

        $comments = $post->comments()
            ->with('user.setting')
            ->whereNotIn('user_id', $request->user()->blockedUserIds())
            ->latest()
            ->paginate(Pagination::perPage($request));

        return ApiResponse::paginated(
            'Comments retrieved successfully',
            'comments',
            $comments,
            CommentResource::collection($comments->items())
        );
    }

    public function store(StoreCommentRequest $request, Post $post): JsonResponse
    {
        if (! $post->user->canViewPrivateContent($request->user())) {
            return ApiResponse::error('You cannot comment on this post.', [], 422);
        }

        $comment = $post->comments()->create([
            'user_id' => $request->user()->id,
            'comment' => $request->input('comment'),
        ]);

        $comment->load('user.setting');

        $this->notifications->createPostCommentedNotification($request->user(), $post, $comment);

        return ApiResponse::success('Comment created successfully', [
            'comment' => CommentResource::make($comment),
            'comments_count' => $post->comments()->count(),
        ], 201);
    }

    public function update(UpdateCommentRequest $request, Comment $comment): JsonResponse
    {
        $this->authorize('update', $comment);

        $comment->update([
            'comment' => $request->input('comment'),
        ]);

        $comment->load('user.setting');

        return ApiResponse::success('Comment updated successfully', [
            'comment' => CommentResource::make($comment),
        ]);
    }

    public function destroy(Request $request, Comment $comment): JsonResponse
    {
        $this->authorize('delete', $comment);

        $post = $comment->post;

        $comment->delete();

        return ApiResponse::success('Comment deleted successfully', [
            'comments_count' => $post->comments()->count(),
        ]);
    }
}
