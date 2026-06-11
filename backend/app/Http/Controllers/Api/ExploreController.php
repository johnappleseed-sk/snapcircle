<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Http\Resources\UserResource;
use App\Models\Post;
use App\Models\User;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExploreController extends Controller
{
    public function posts(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'sort' => ['sometimes', 'string', 'in:latest,popular'],
        ]);

        $posts = $this->basePostQuery($request)
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where('content', 'like', "%{$search}%");
            });

        $this->applyPostSort($posts, $validated['sort'] ?? 'latest');

        return $this->postPageResponse(
            'Explore posts fetched successfully',
            $posts->paginate(Pagination::perPage($request))->withQueryString()
        );
    }

    public function users(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $users = $this->baseUserQuery($request)
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('bio', 'like', "%{$search}%");
                });
            })
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return $this->userPageResponse('Explore users fetched successfully', $users);
    }

    public function trendingPosts(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
            'days' => ['sometimes', 'integer', 'min:1', 'max:365'],
        ]);

        $days = (int) ($validated['days'] ?? 7);
        $posts = $this->basePostQuery($request)
            ->where('created_at', '>=', now()->subDays($days));

        if (! $posts->exists()) {
            $posts = $this->basePostQuery($request);
        }

        $posts->orderByRaw('(likes_count * 2 + comments_count * 3 + saved_posts_count) desc')
            ->latest();

        return $this->postPageResponse(
            'Trending posts fetched successfully',
            $posts->paginate(Pagination::perPage($request))->withQueryString()
        );
    }

    public function recommendedUsers(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $authUser = $request->user();
        $followingIds = $authUser->following()->pluck('users.id');

        $users = $this->baseUserQuery($request)
            ->whereNotIn('id', $followingIds)
            ->orderByDesc('followers_count')
            ->orderByDesc('posts_count')
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return $this->userPageResponse('Recommended users fetched successfully', $users);
    }

    public function search(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'q' => ['required', 'string', 'max:255'],
            'type' => ['sometimes', 'string', 'in:all,posts,users'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $type = $validated['type'] ?? 'all';
        $query = $validated['q'];
        $perPage = Pagination::perPage($request);
        $data = [];

        if ($type === 'all' || $type === 'posts') {
            $posts = $this->basePostQuery($request)
                ->where('content', 'like', "%{$query}%")
                ->latest()
                ->limit($perPage)
                ->get();
            $data['posts'] = PostResource::collection($posts);
        }

        if ($type === 'all' || $type === 'users') {
            $users = $this->baseUserQuery($request)
                ->where(function ($builder) use ($query): void {
                    $builder->where('name', 'like', "%{$query}%")
                        ->orWhere('email', 'like', "%{$query}%")
                        ->orWhere('bio', 'like', "%{$query}%");
                })
                ->latest()
                ->limit($perPage)
                ->get();
            $data['users'] = UserResource::collection($users);
        }

        return ApiResponse::success('Search results fetched successfully', $data);
    }

    private function basePostQuery(Request $request)
    {
        $authUser = $request->user();

        return Post::query()
            ->with('user.setting')
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ])
            ->whereNotIn('user_id', $authUser->blockedUserIds());
    }

    private function baseUserQuery(Request $request)
    {
        $authUser = $request->user();

        return User::query()
            ->where('id', '!=', $authUser->id)
            ->whereNotIn('id', $authUser->blockedUserIds())
            ->with('setting')
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $authUser->id),
            ]);
    }

    private function applyPostSort($posts, string $sort): void
    {
        if ($sort === 'popular') {
            $posts->orderByRaw('(likes_count + comments_count) desc')
                ->latest();

            return;
        }

        $posts->latest();
    }

    private function postPageResponse(string $message, $posts): JsonResponse
    {
        return ApiResponse::success($message, [
            'data' => PostResource::collection($posts->items()),
            'current_page' => $posts->currentPage(),
            'last_page' => $posts->lastPage(),
            'per_page' => $posts->perPage(),
            'total' => $posts->total(),
        ]);
    }

    private function userPageResponse(string $message, $users): JsonResponse
    {
        return ApiResponse::success($message, [
            'data' => UserResource::collection($users->items()),
            'current_page' => $users->currentPage(),
            'last_page' => $users->lastPage(),
            'per_page' => $users->perPage(),
            'total' => $users->total(),
        ]);
    }
}
