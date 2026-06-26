<?php

namespace App\Http\Controllers\Api\Admin;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Http\Resources\PostResource;
use App\Models\Comment;
use App\Models\Post;
use App\Models\Report;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class AdminContentController extends Controller
{
    public function posts(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'status' => [
                'sometimes',
                'string',
                Rule::in(['reported', 'pending_report', 'unreported']),
            ],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $posts = Post::query()
            ->with(['user.setting', 'media'])
            ->withCount([
                'likes',
                'comments',
                'savedPosts',
                'reports',
                'reports as pending_reports_count' => fn ($query) => $query
                    ->where('status', Report::STATUS_PENDING),
            ])
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('content', 'like', "%{$search}%")
                        ->orWhereHas('user', function ($query) use ($search): void {
                            $query->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%")
                                ->orWhere('username', 'like', "%{$search}%");
                        });
                });
            })
            ->when(isset($validated['status']), fn ($query) => match ($validated['status']) {
                'reported' => $query->whereHas('reports'),
                'pending_report' => $query->whereHas(
                    'reports',
                    fn ($query) => $query->where('status', Report::STATUS_PENDING)
                ),
                'unreported' => $query->whereDoesntHave('reports'),
            })
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
                'pending_reports_count' => (int) $post->pending_reports_count,
            ])->values()
        );
    }

    public function deletePost(Post $post): JsonResponse
    {
        $paths = $post->media()->pluck('path')
            ->when($post->image_path, fn ($collection) => $collection->push($post->image_path))
            ->filter(fn (?string $path): bool => filled($path) && ! str_starts_with($path, 'http'))
            ->unique()
            ->values();

        Storage::disk('public')->delete($paths->all());
        $post->media()->delete();
        $post->delete();

        return ApiResponse::success('Post deleted by moderation.');
    }

    public function comments(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'status' => [
                'sometimes',
                'string',
                Rule::in(['reported', 'pending_report', 'unreported']),
            ],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $comments = Comment::query()
            ->with(['user.setting', 'post.user.setting'])
            ->withCount([
                'reports',
                'reports as pending_reports_count' => fn ($query) => $query
                    ->where('status', Report::STATUS_PENDING),
            ])
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('comment', 'like', "%{$search}%")
                        ->orWhereHas('user', function ($query) use ($search): void {
                            $query->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%")
                                ->orWhere('username', 'like', "%{$search}%");
                        })
                        ->orWhereHas(
                            'post',
                            fn ($query) => $query->where('content', 'like', "%{$search}%")
                        );
                });
            })
            ->when(isset($validated['status']), fn ($query) => match ($validated['status']) {
                'reported' => $query->whereHas('reports'),
                'pending_report' => $query->whereHas(
                    'reports',
                    fn ($query) => $query->where('status', Report::STATUS_PENDING)
                ),
                'unreported' => $query->whereDoesntHave('reports'),
            })
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
                'pending_reports_count' => (int) $comment->pending_reports_count,
            ])->values()
        );
    }

    public function deleteComment(Comment $comment): JsonResponse
    {
        $comment->delete();

        return ApiResponse::success('Comment deleted by moderation.');
    }
}
