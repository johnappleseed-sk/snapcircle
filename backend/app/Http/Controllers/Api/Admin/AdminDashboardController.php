<?php

namespace App\Http\Controllers\Api\Admin;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Comment;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\Story;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class AdminDashboardController extends Controller
{
    public function index(): JsonResponse
    {
        return ApiResponse::success('Admin dashboard fetched successfully', [
            'total_users' => User::query()->count(),
            'active_users' => User::query()->where('account_status', 'active')->count(),
            'banned_users' => User::query()->where('account_status', 'banned')->count(),
            'total_posts' => Post::query()->count(),
            'total_comments' => Comment::query()->count(),
            'total_reports' => Report::query()->count(),
            'pending_reports' => Report::query()->where('status', Report::STATUS_PENDING)->count(),
            'total_stories' => Story::query()->count(),
            'total_messages' => Message::query()->count(),
            'new_users_today' => User::query()->whereDate('created_at', today())->count(),
            'new_posts_today' => Post::query()->whereDate('created_at', today())->count(),
            'reports_today' => Report::query()->whereDate('created_at', today())->count(),
        ]);
    }
}
