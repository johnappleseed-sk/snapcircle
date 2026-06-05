<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\PostResource;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()
            ->load('setting')
            ->loadCount(['posts', 'followers', 'following']);

        $user->is_followed_by_me = false;

        return ApiResponse::success('Profile retrieved successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $avatar = $user->avatar;

        if ($request->hasFile('avatar')) {
            $this->deleteLocalAvatar($user->avatar);
            $avatar = $request->file('avatar')->store('avatars', 'public');
        }

        $coverImage = $user->cover_image;
        if ($request->hasFile('cover_image')) {
            $this->deleteLocalImage($user->cover_image);
            $coverImage = $request->file('cover_image')->store('covers', 'public');
        }

        $user->update([
            'name' => $request->input('name'),
            'username' => $request->filled('username') ? $request->string('username')->toString() : null,
            'bio' => $request->filled('bio') ? $request->string('bio')->toString() : null,
            'location' => $request->filled('location') ? $request->string('location')->toString() : null,
            'website' => $request->filled('website') ? $request->string('website')->toString() : null,
            'avatar' => $avatar,
            'cover_image' => $coverImage,
            'is_private' => $request->has('is_private') ? $request->boolean('is_private') : (bool) $user->is_private,
        ]);

        $user->load('setting')->loadCount(['posts', 'followers', 'following']);
        $user->is_followed_by_me = false;

        return ApiResponse::success('Profile updated successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    public function users(Request $request): JsonResponse
    {
        $authUser = $request->user();

        $users = User::query()
            ->with('setting')
            ->withCount(['posts', 'followers', 'following'])
            ->withExists([
                'followers as is_followed_by_me' => fn ($query) => $query->where('follower_id', $authUser->id),
            ])
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

        return ApiResponse::paginated(
            'Users retrieved successfully',
            'users',
            $users,
            UserResource::collection($users->items())
        );
    }

    public function show(Request $request, User $user): JsonResponse
    {
        $user->load('setting')->loadCount(['posts', 'followers', 'following']);
        $user->is_followed_by_me = $user->followers()
            ->where('follower_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('User profile retrieved successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    public function showByUsername(Request $request, string $username): JsonResponse
    {
        $user = User::query()
            ->where('username', $username)
            ->first();

        if (! $user) {
            return ApiResponse::error('User not found', [], 404);
        }

        return $this->show($request, $user);
    }

    public function posts(Request $request, User $user): JsonResponse
    {
        $perPage = Pagination::perPage($request);
        $sort = $request->string('sort')->toString();

        $postsQuery = $user->posts()
            ->with('user.setting')
            ->withCount(['likes', 'comments', 'savedPosts'])
            ->withExists([
                'likes as liked_by_me' => fn ($query) => $query->where('user_id', $request->user()->id),
                'savedPosts as saved_by_me' => fn ($query) => $query->where('user_id', $request->user()->id),
            ]);

        if ($sort === 'popular') {
            $postsQuery
                ->orderByRaw('(likes_count + comments_count) desc')
                ->latest();
        } else {
            $postsQuery->latest();
        }

        $posts = $postsQuery
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::paginated(
            'User posts retrieved successfully',
            'posts',
            $posts,
            PostResource::collection($posts->items())
        );
    }

    private function deleteLocalAvatar(?string $avatar): void
    {
        $this->deleteLocalImage($avatar);
    }

    private function deleteLocalImage(?string $path): void
    {
        if (! $path || str_starts_with($path, 'http')) {
            return;
        }

        Storage::disk('public')->delete($path);
    }
}
