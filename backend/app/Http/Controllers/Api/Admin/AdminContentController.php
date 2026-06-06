<?php

namespace App\Http\Controllers\Api\Admin;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Http\Resources\PostResource;
use App\Models\Comment;
use App\Models\Post;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminContentController extends Controller
{
    public function posts(Request $request): JsonResponse
    {
        $posts = Post::query()
            ->with('user.setting')
            ->withCount(['likes', 'comments', 'savedPosts', 'reports'])
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return ApiResponse::paginated(
            'Admin posts fetched successfully',
            'posts',
            $posts,
            collect($posts->items())->map(fn (Post $post) => [
                ...PostResource::make($post)->resolve(),
                'reports_count' => (int) $post->reports_count,
            ])->values()
        );
    }

    public function deletePost(Post $post): JsonResponse
    {
        $post->delete();

        return ApiResponse::success('Post deleted by moderation.');
    }

    public function comments(Request $request): JsonResponse
    {
        $comments = Comment::query()
            ->with(['user.setting', 'post.user.setting'])
            ->withCount('reports')
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return ApiResponse::paginated(
            'Admin comments fetched successfully',
            'comments',
            $comments,
            collect($comments->items())->map(fn (Comment $comment) => [
                ...CommentResource::make($comment)->resolve(),
                'reports_count' => (int) $comment->reports_count,
            ])->values()
        );
    }

    public function deleteComment(Comment $comment): JsonResponse
    {
        $comment->delete();

        return ApiResponse::success('Comment deleted by moderation.');
    }
}
