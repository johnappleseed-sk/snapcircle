<?php

namespace App\Http\Controllers\Api\Admin;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'role' => ['sometimes', 'string', Rule::in(['user', 'admin', 'moderator'])],
            'account_status' => ['sometimes', 'string', Rule::in(['active', 'deactivated', 'banned'])],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $users = User::query()
            ->with('setting')
            ->withCount(['posts', 'followers', 'following', 'reports'])
            ->when(isset($validated['role']), fn ($query) => $query->where('role', $validated['role']))
            ->when(isset($validated['account_status']), fn ($query) => $query->where('account_status', $validated['account_status']))
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('username', 'like', "%{$search}%");
                });
            })
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return ApiResponse::paginated(
            'Admin users fetched successfully',
            'users',
            $users,
            collect($users->items())->map(fn (User $user) => $this->adminUserData($user))->values()
        );
    }

    public function show(User $user): JsonResponse
    {
        $user->load('setting')->loadCount(['posts', 'followers', 'following', 'reports']);

        return ApiResponse::success('Admin user fetched successfully', [
            'user' => $this->adminUserData($user),
        ]);
    }

    public function ban(Request $request, User $user): JsonResponse
    {
        if ($request->user()->id === $user->id) {
            return ApiResponse::error('You cannot ban your own account.', [], 422);
        }

        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);

        $user->update([
            'account_status' => 'banned',
            'banned_at' => now(),
            'ban_reason' => $validated['reason'],
        ]);

        $user->tokens()->delete();
        $user->load('setting')->loadCount(['posts', 'followers', 'following', 'reports']);

        return ApiResponse::success('User banned successfully', [
            'user' => $this->adminUserData($user),
        ]);
    }

    public function unban(User $user): JsonResponse
    {
        $user->update([
            'account_status' => 'active',
            'banned_at' => null,
            'ban_reason' => null,
        ]);

        $user->load('setting')->loadCount(['posts', 'followers', 'following', 'reports']);

        return ApiResponse::success('User unbanned successfully', [
            'user' => $this->adminUserData($user),
        ]);
    }

    public function updateRole(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(['user', 'admin', 'moderator'])],
        ]);

        if ($request->user()->role === 'moderator' && $validated['role'] === 'admin') {
            return ApiResponse::error('Moderators cannot assign admin role.', [], 403);
        }

        $user->update(['role' => $validated['role']]);
        $user->load('setting')->loadCount(['posts', 'followers', 'following', 'reports']);

        return ApiResponse::success('User role updated successfully', [
            'user' => $this->adminUserData($user),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function adminUserData(User $user): array
    {
        return [
            ...UserResource::make($user)->resolve(),
            'banned_at' => $user->banned_at?->toISOString(),
            'ban_reason' => $user->ban_reason,
            'reports_count' => (int) ($user->reports_count ?? $user->reports()->count()),
        ];
    }
}
