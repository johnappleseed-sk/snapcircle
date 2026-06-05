<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
            'filter' => ['sometimes', 'string', 'in:all,unread,read'],
        ]);

        $filter = $validated['filter'] ?? 'all';
        $perPage = Pagination::perPage($request, 'notifications_per_page');

        $notifications = Notification::query()
            ->where('user_id', $request->user()->id)
            ->with(['actor.setting', 'post.user.setting', 'comment.user.setting'])
            ->when($filter === 'unread', fn ($query) => $query->whereNull('read_at'))
            ->when($filter === 'read', fn ($query) => $query->whereNotNull('read_at'))
            ->latest()
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::success('Notifications fetched successfully', [
            'data' => NotificationResource::collection($notifications->items()),
            'current_page' => $notifications->currentPage(),
            'last_page' => $notifications->lastPage(),
            'per_page' => $notifications->perPage(),
            'total' => $notifications->total(),
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        return ApiResponse::success('Unread notification count fetched successfully', [
            'unread_count' => Notification::query()
                ->where('user_id', $request->user()->id)
                ->whereNull('read_at')
                ->count(),
        ]);
    }

    public function markAsRead(Request $request, Notification $notification): JsonResponse
    {
        $this->authorize('update', $notification);

        if (! $notification->read_at) {
            $notification->update(['read_at' => now()]);
        }

        $notification->load(['actor.setting', 'post.user.setting', 'comment.user.setting']);

        return ApiResponse::success('Notification marked as read', [
            'notification' => NotificationResource::make($notification),
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $updatedCount = Notification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return ApiResponse::success('All notifications marked as read', [
            'updated_count' => $updatedCount,
        ]);
    }

    public function destroy(Request $request, Notification $notification): JsonResponse
    {
        $this->authorize('delete', $notification);

        $notification->delete();

        return ApiResponse::success('Notification deleted successfully');
    }
}
