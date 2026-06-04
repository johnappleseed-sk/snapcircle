<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    /**
     * Return a standard JSON response for API endpoints.
     *
     * @param  array<string, mixed>  $data
     */
    public static function success(array $data, int $status = 200): JsonResponse
    {
        return response()->json($data, $status);
    }
}
