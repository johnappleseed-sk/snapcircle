<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Models\Comment;
use App\Models\Post;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CommentController extends Controller
{
    public function index(Post $post): JsonResponse
    {
        $comments = $post->comments()
            ->with('user')
            ->latest()
            ->paginate(10);

        return ApiResponse::success('Comments retrieved successfully', [
            'comments' => CommentResource::collection($comments->items()),
            'meta' => [
                'current_page' => $comments->currentPage(),
                'last_page' => $comments->lastPage(),
                'per_page' => $comments->perPage(),
                'total' => $comments->total(),
            ],
            'links' => [
                'first' => $comments->url(1),
                'last' => $comments->url($comments->lastPage()),
                'prev' => $comments->previousPageUrl(),
                'next' => $comments->nextPageUrl(),
            ],
        ]);
    }

    public function store(Request $request, Post $post): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'comment' => ['required', 'string', 'max:1000'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation failed', $validator->errors()->toArray(), 422);
        }

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

    public function update(Request $request, Comment $comment): JsonResponse
    {
        if ($comment->user_id !== $request->user()->id) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        $validator = Validator::make($request->all(), [
            'comment' => ['required', 'string', 'max:1000'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation failed', $validator->errors()->toArray(), 422);
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
