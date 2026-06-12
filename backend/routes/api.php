<?php

use App\Http\Controllers\Api\Admin\AdminContentController;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminReportController;
use App\Http\Controllers\Api\Admin\AdminUserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BlockController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\ExploreController;
use App\Http\Controllers\Api\FeedStatusController;
use App\Http\Controllers\Api\FollowController;
use App\Http\Controllers\Api\LikeController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SavedPostController;
use App\Http\Controllers\Api\SettingsController;
use App\Http\Controllers\Api\StoryController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public API Routes
|--------------------------------------------------------------------------
*/
Route::get('/health', fn () => response()->json([
    'status' => 'ok',
    'app' => 'SnapCircle API',
]));

Route::post('/auth/google', [AuthController::class, 'google'])->middleware('throttle:10,1');
Route::post('/auth/facebook', [AuthController::class, 'facebook'])->middleware('throttle:10,1');
Route::post('/auth/demo', [AuthController::class, 'demo'])->middleware('throttle:10,1');
Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:5,1');

/*
|--------------------------------------------------------------------------
| Protected API Routes
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/settings', [SettingsController::class, 'show']);
    Route::put('/settings', [SettingsController::class, 'update']);
    Route::put('/settings/privacy', [SettingsController::class, 'privacy']);
    Route::put('/account/deactivate', [SettingsController::class, 'deactivate'])->middleware('throttle:5,1');
    Route::delete('/account', [SettingsController::class, 'destroy'])->middleware('throttle:5,1');

    Route::middleware('account.active')->group(function (): void {
        Route::get('/blocks', [BlockController::class, 'index']);
        Route::post('/users/{user}/block', [BlockController::class, 'store']);
        Route::delete('/users/{user}/block', [BlockController::class, 'destroy']);
        Route::get('/users/{user}/block-status', [BlockController::class, 'status']);

        Route::get('/profile', [ProfileController::class, 'profile']);
        Route::put('/profile', [ProfileController::class, 'update']);
        Route::get('/users', [ProfileController::class, 'users']);
        Route::get('/users/username/{username}', [ProfileController::class, 'showByUsername']);
        Route::get('/users/{user}', [ProfileController::class, 'show']);
        Route::get('/users/{user}/posts', [ProfileController::class, 'posts']);
        Route::get('/users/{user}/stories', [StoryController::class, 'userStories']);
        Route::post('/users/{user}/report', [ReportController::class, 'reportUser']);
        Route::post('/reports', [ReportController::class, 'storeGeneric']);

        Route::get('/explore/posts', [ExploreController::class, 'posts']);
        Route::get('/explore/users', [ExploreController::class, 'users']);
        Route::get('/explore/trending-posts', [ExploreController::class, 'trendingPosts']);
        Route::get('/explore/recommended-users', [ExploreController::class, 'recommendedUsers']);
        Route::get('/explore/search', [ExploreController::class, 'search']);

        Route::post('/users/{user}/follow', [FollowController::class, 'store'])->middleware('throttle:30,1');
        Route::delete('/users/{user}/follow', [FollowController::class, 'destroy']);
        Route::get('/follow-requests', [FollowController::class, 'requests']);
        Route::post('/follow-requests/{user}/approve', [FollowController::class, 'approve']);
        Route::post('/follow-requests/{user}/reject', [FollowController::class, 'reject']);
        Route::delete('/followers/{user}', [FollowController::class, 'removeFollower']);
        Route::get('/users/{user}/followers', [FollowController::class, 'followers']);
        Route::get('/users/{user}/following', [FollowController::class, 'following']);

        Route::get('/feed/status', [FeedStatusController::class, 'index']);

        Route::get('/posts', [PostController::class, 'index']);
        Route::post('/posts', [PostController::class, 'store'])->middleware('throttle:20,1');
        Route::get('/posts/{post}', [PostController::class, 'show']);
        Route::put('/posts/{post}', [PostController::class, 'update']);
        Route::delete('/posts/{post}', [PostController::class, 'destroy']);
        Route::post('/posts/{post}/report', [ReportController::class, 'reportPost']);

        Route::get('/posts/{post}/comments/status', [FeedStatusController::class, 'comments']);
        Route::get('/posts/{post}/comments', [CommentController::class, 'index']);
        Route::post('/posts/{post}/comments', [CommentController::class, 'store'])->middleware('throttle:30,1');
        Route::put('/comments/{comment}', [CommentController::class, 'update']);
        Route::delete('/comments/{comment}', [CommentController::class, 'destroy']);
        Route::post('/comments/{comment}/report', [ReportController::class, 'reportComment']);

        Route::post('/posts/{post}/like', [LikeController::class, 'store'])->middleware('throttle:60,1');
        Route::delete('/posts/{post}/like', [LikeController::class, 'destroy']);

        Route::post('/posts/{post}/save', [SavedPostController::class, 'store']);
        Route::delete('/posts/{post}/save', [SavedPostController::class, 'destroy']);
        Route::get('/saved-posts', [SavedPostController::class, 'index']);

        Route::get('/stories', [StoryController::class, 'index']);
        Route::post('/stories', [StoryController::class, 'store'])->middleware('throttle:10,1');
        Route::get('/stories/{story}', [StoryController::class, 'show']);
        Route::delete('/stories/{story}', [StoryController::class, 'destroy']);
        Route::post('/stories/{story}/view', [StoryController::class, 'markAsViewed']);

        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
        Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::put('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
        Route::delete('/notifications/{notification}', [NotificationController::class, 'destroy']);

        Route::get('/conversations', [ConversationController::class, 'index']);
        Route::post('/conversations', [ConversationController::class, 'store']);
        Route::get('/conversations/{conversation}', [ConversationController::class, 'show']);
        Route::delete('/conversations/{conversation}', [ConversationController::class, 'destroy']);
        Route::get('/conversations/{conversation}/messages', [MessageController::class, 'index']);
        Route::post('/conversations/{conversation}/messages', [MessageController::class, 'store'])->middleware('throttle:60,1');
        Route::put('/messages/{message}/read', [MessageController::class, 'markAsRead']);
    });

    Route::middleware('admin')->prefix('admin')->group(function (): void {
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);

        Route::get('/reports', [AdminReportController::class, 'index']);
        Route::get('/reports/{report}', [AdminReportController::class, 'show']);
        Route::put('/reports/{report}/status', [AdminReportController::class, 'updateStatus']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::get('/users/{user}', [AdminUserController::class, 'show']);
        Route::put('/users/{user}/ban', [AdminUserController::class, 'ban']);
        Route::put('/users/{user}/unban', [AdminUserController::class, 'unban']);
        Route::put('/users/{user}/role', [AdminUserController::class, 'updateRole']);

        Route::get('/posts', [AdminContentController::class, 'posts']);
        Route::delete('/posts/{post}', [AdminContentController::class, 'deletePost']);
        Route::get('/comments', [AdminContentController::class, 'comments']);
        Route::delete('/comments/{comment}', [AdminContentController::class, 'deleteComment']);
    });
});
