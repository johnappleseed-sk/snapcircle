<?php

use App\Http\Controllers\AdminWebController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

Route::prefix('admin')->name('admin.')->group(function (): void {
    Route::get('/login', [AdminWebController::class, 'login'])->name('login');
    Route::post('/login', [AdminWebController::class, 'authenticate'])->name('authenticate');

    Route::middleware(['auth', 'admin'])->group(function (): void {
        Route::post('/logout', [AdminWebController::class, 'logout'])->name('logout');
        Route::get('/', [AdminWebController::class, 'dashboard'])->name('dashboard');
        Route::get('/roles', [AdminWebController::class, 'roles'])->name('roles.index');
        Route::get('/audit', [AdminWebController::class, 'audit'])->name('audit.index');
        Route::get('/reports', [AdminWebController::class, 'reports'])->name('reports.index');
        Route::get('/reports/{report}', [AdminWebController::class, 'report'])->name('reports.show');
        Route::put('/reports/{report}', [AdminWebController::class, 'updateReport'])->name('reports.update');
        Route::get('/users', [AdminWebController::class, 'users'])->name('users.index');
        Route::get('/users/{user}', [AdminWebController::class, 'user'])->name('users.show');
        Route::put('/users/{user}/role', [AdminWebController::class, 'updateUserRole'])->name('users.role');
        Route::put('/users/{user}/ban', [AdminWebController::class, 'banUser'])->name('users.ban');
        Route::put('/users/{user}/unban', [AdminWebController::class, 'unbanUser'])->name('users.unban');
        Route::get('/posts', [AdminWebController::class, 'posts'])->name('posts.index');
        Route::delete('/posts/{post}', [AdminWebController::class, 'deletePost'])->name('posts.destroy');
        Route::get('/comments', [AdminWebController::class, 'comments'])->name('comments.index');
        Route::delete('/comments/{comment}', [AdminWebController::class, 'deleteComment'])->name('comments.destroy');
    });
});
