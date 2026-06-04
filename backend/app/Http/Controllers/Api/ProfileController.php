<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()
            ->loadCount(['posts', 'followers', 'following']);

        $user->is_followed_by_me = false;

        return ApiResponse::success('Profile retrieved successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'bio' => ['nullable', 'string', 'max:500'],
            'avatar' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation failed', $validator->errors()->toArray(), 422);
        }

        $user = $request->user();
        $avatar = $user->avatar;

        if ($request->hasFile('avatar')) {
            $this->deleteLocalAvatar($user->avatar);
            $avatar = $request->file('avatar')->store('avatars', 'public');
        }

        $user->update([
            'name' => $request->input('name'),
            'bio' => $request->input('bio'),
            'avatar' => $avatar,
        ]);

        $user->loadCount(['posts', 'followers', 'following']);
        $user->is_followed_by_me = false;

        return ApiResponse::success('Profile updated successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    public function users(Request $request): JsonResponse
    {
        $authUser = $request->user();

        $users = User::query()
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
            ->paginate(10)
            ->withQueryString();

        return ApiResponse::success('Users retrieved successfully', [
            'users' => UserResource::collection($users->items()),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
            'links' => [
                'first' => $users->url(1),
                'last' => $users->url($users->lastPage()),
                'prev' => $users->previousPageUrl(),
                'next' => $users->nextPageUrl(),
            ],
        ]);
    }

    public function show(Request $request, User $user): JsonResponse
    {
        $user->loadCount(['posts', 'followers', 'following']);
        $user->is_followed_by_me = $user->followers()
            ->where('follower_id', $request->user()->id)
            ->exists();

        return ApiResponse::success('User profile retrieved successfully', [
            'user' => UserResource::make($user),
        ]);
    }

    private function deleteLocalAvatar(?string $avatar): void
    {
        if (! $avatar || str_starts_with($avatar, 'http')) {
            return;
        }

        Storage::disk('public')->delete($avatar);
    }
}
