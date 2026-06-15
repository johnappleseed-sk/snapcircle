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
use Illuminate\Support\Str;

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

    public function trendingTags(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'days' => ['sometimes', 'integer', 'min:1', 'max:365'],
            'limit' => ['sometimes', 'integer', 'min:1', 'max:30'],
        ]);

        $days = (int) ($validated['days'] ?? 30);
        $limit = (int) ($validated['limit'] ?? 12);
        $tags = $this->collectTrendingTags($request, $days, $limit);

        if ($tags === []) {
            $tags = $this->collectTrendingTags($request, 365, $limit);
        }

        return ApiResponse::success('Trending tags fetched successfully', [
            'data' => $tags,
        ]);
    }

    public function tagPosts(Request $request, string $tag): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
            'sort' => ['sometimes', 'string', 'in:latest,popular'],
        ]);
        $normalizedTag = $this->normalizeTag($tag);

        if ($normalizedTag === '') {
            return ApiResponse::error('Invalid hashtag.', [], 422);
        }

        $posts = $this->basePostQuery($request);
        $this->applyTagContentFilter($posts, $normalizedTag);

        $this->applyPostSort($posts, $validated['sort'] ?? 'latest');

        return $this->postPageResponse(
            'Tag posts fetched successfully',
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

        return $this->visiblePostQuery($request)
            ->with(['user.setting', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $authUser->id),
            ]);
    }

    private function visiblePostQuery(Request $request)
    {
        $authUser = $request->user();

        return Post::query()
            ->visibleTo($authUser)
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

    private function collectTrendingTags(Request $request, int $days, int $limit): array
    {
        $posts = $this->visiblePostQuery($request)
            ->whereNotNull('content')
            ->where('created_at', '>=', now()->subDays($days))
            ->latest()
            ->limit(3000)
            ->get(['id', 'content', 'created_at']);

        $tags = [];

        foreach ($posts as $post) {
            foreach ($this->extractTags($post->content ?? '') as $tag) {
                $tags[$tag] ??= [
                    'tag' => $tag,
                    'label' => "#{$tag}",
                    'posts_count' => 0,
                    'latest_posted_at' => null,
                ];
                $tags[$tag]['posts_count']++;

                $postedAt = optional($post->created_at)->toISOString();
                if ($postedAt && (! $tags[$tag]['latest_posted_at'] || $postedAt > $tags[$tag]['latest_posted_at'])) {
                    $tags[$tag]['latest_posted_at'] = $postedAt;
                }
            }
        }

        usort($tags, function (array $a, array $b): int {
            $countComparison = $b['posts_count'] <=> $a['posts_count'];

            if ($countComparison !== 0) {
                return $countComparison;
            }

            return ($b['latest_posted_at'] ?? '') <=> ($a['latest_posted_at'] ?? '');
        });

        return array_slice(array_values($tags), 0, $limit);
    }

    private function extractTags(string $content): array
    {
        if (! preg_match_all('/#[\p{L}\p{N}_]{2,50}/u', $content, $matches)) {
            return [];
        }

        $tags = [];
        foreach ($matches[0] as $match) {
            $tag = $this->normalizeTag($match);
            if ($tag === '' || preg_match('/^\d+$/', $tag)) {
                continue;
            }

            $tags[$tag] = $tag;
        }

        return array_values($tags);
    }

    private function normalizeTag(string $tag): string
    {
        $tag = ltrim(Str::lower(trim($tag)), '#');
        $tag = preg_replace('/[^\p{L}\p{N}_]/u', '', $tag) ?? '';

        return trim($tag);
    }

    private function applyTagContentFilter($posts, string $tag): void
    {
        $patterns = [
            "%#{$tag}",
            "%#{$tag} %",
            "%#{$tag}\n%",
            "%#{$tag}\r%",
            "%#{$tag}\t%",
            "%#{$tag}.%",
            "%#{$tag},%",
            "%#{$tag}!%",
            "%#{$tag}?%",
        ];

        $posts->where(function ($query) use ($patterns): void {
            foreach ($patterns as $index => $pattern) {
                if ($index === 0) {
                    $query->where('content', 'like', $pattern);
                    continue;
                }

                $query->orWhere('content', 'like', $pattern);
            }
        });
    }
}
