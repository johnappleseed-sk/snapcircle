<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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

    public function update(UpdateProfileRequest $request): JsonResponse
    {
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

        return ApiResponse::paginated(
            'Users retrieved successfully',
            'users',
            $users,
            UserResource::collection($users->items())
        );
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
