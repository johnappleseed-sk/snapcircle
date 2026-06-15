<?php

namespace App\Http\Middleware;

use App\Helpers\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $role = $request->user()?->role;

        if (! in_array($role, ['admin', 'moderator'], true)) {
            if (! $request->expectsJson() && ! $request->is('api/*')) {
                return redirect()->route('admin.login');
            }

            return ApiResponse::error('Admin access required.', [], 403);
        }

        return $next($request);
    }
}
