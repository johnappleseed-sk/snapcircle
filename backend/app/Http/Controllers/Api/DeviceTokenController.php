<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DeviceTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', 'string', Rule::in(['android'])],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $deviceToken = DeviceToken::query()->updateOrCreate([
            'token' => $validated['token'],
        ], [
            'user_id' => $request->user()->id,
            'platform' => $validated['platform'] ?? 'android',
            'device_name' => $validated['device_name'] ?? null,
            'last_used_at' => now(),
        ]);

        return ApiResponse::success('Device token registered successfully', [
            'device_token' => [
                'id' => $deviceToken->id,
                'platform' => $deviceToken->platform,
                'device_name' => $deviceToken->device_name,
                'last_used_at' => $deviceToken->last_used_at?->toISOString(),
            ],
        ], $deviceToken->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        DeviceToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $validated['token'])
            ->delete();

        return ApiResponse::success('Device token removed successfully');
    }
}
