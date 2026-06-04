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
    public static function success(string $message, array $data = [], int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    /**
     * Return a standard JSON error response for API endpoints.
     *
     * @param  array<string, mixed>  $errors
     */
    public static function error(string $message, array $errors = [], int $status = 400): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }
}
