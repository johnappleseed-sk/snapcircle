<?php

namespace App\Helpers;

use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

class ApiResponse
{
    /**
     * Return a standard JSON success response.
     *
     * @param  array<string, mixed>|null  $data
     */
    public static function success(string $message, ?array $data = null, int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data ?? new \stdClass(),
        ], $status);
    }

    /**
     * Return a standard JSON success response for paginated collections.
     */
    public static function paginated(
        string $message,
        string $dataKey,
        LengthAwarePaginator $paginator,
        mixed $items,
        int $status = 200
    ): JsonResponse {
        return self::success($message, [
            $dataKey => $items,
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
            'links' => [
                'first' => $paginator->url(1),
                'last' => $paginator->url($paginator->lastPage()),
                'prev' => $paginator->previousPageUrl(),
                'next' => $paginator->nextPageUrl(),
            ],
        ], $status);
    }

    /**
     * Return a standard JSON error response.
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
