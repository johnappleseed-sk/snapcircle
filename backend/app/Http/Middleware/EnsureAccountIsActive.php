<?php

namespace App\Http\Middleware;

use App\Helpers\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $status = $request->user()?->account_status ?? 'active';

        if ($status !== 'active') {
            return ApiResponse::error('Your account is not active.', [], 403);
        }

        return $next($request);
    }
}
