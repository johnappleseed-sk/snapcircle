<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCommentRequest;
use App\Http\Requests\UpdateCommentRequest;
use App\Http\Resources\CommentResource;
use App\Models\Comment;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function index(Post $post): JsonResponse
    {
        $comments = $post->comments()
            ->with('user')
            ->latest()
            ->paginate(10);

        return ApiResponse::paginated(
            'Comments retrieved successfully',
            'comments',
            $comments,
            CommentResource::collection($comments->items())
        );
    }

    public function store(StoreCommentRequest $request, Post $post): JsonResponse
    {
        $comment = $post->comments()->create([
            'user_id' => $request->user()->id,
            'comment' => $request->input('comment'),
        ]);

        $comment->load('user');

        return ApiResponse::success('Comment created successfully', [
            'comment' => CommentResource::make($comment),
            'comments_count' => $post->comments()->count(),
        ], 201);
    }

    public function update(UpdateCommentRequest $request, Comment $comment): JsonResponse
    {
        if ($comment->user_id !== $request->user()->id) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        $comment->update([
            'comment' => $request->input('comment'),
        ]);

        $comment->load('user');

        return ApiResponse::success('Comment updated successfully', [
            'comment' => CommentResource::make($comment),
        ]);
    }

    public function destroy(Request $request, Comment $comment): JsonResponse
    {
        if ($comment->user_id !== $request->user()->id) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        $post = $comment->post;

        $comment->delete();

        return ApiResponse::success('Comment deleted successfully', [
            'comments_count' => $post->comments()->count(),
        ]);
    }
}
