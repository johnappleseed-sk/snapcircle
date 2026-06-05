<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateSettingsRequest;
use App\Http\Resources\SettingsResource;
use App\Models\UserSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $settings = $this->settingsFor($request);

        return ApiResponse::success('Settings fetched successfully', [
            'settings' => SettingsResource::make($settings),
        ]);
    }

    public function update(UpdateSettingsRequest $request): JsonResponse
    {
        $settings = $this->settingsFor($request);

        $settings->update($request->safe()->only([
            'allow_messages',
            'show_email',
            'push_notifications_enabled',
            'email_notifications_enabled',
            'marketing_emails_enabled',
        ]));

        return ApiResponse::success('Settings updated successfully', [
            'settings' => SettingsResource::make($settings->fresh('user')),
        ]);
    }

    public function deactivate(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update(['account_status' => 'deactivated']);
        $user->tokens()->delete();

        return ApiResponse::success('Account deactivated successfully');
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update(['account_status' => 'deactivated']);
        $user->tokens()->delete();

        return ApiResponse::success('Account deletion request received. Account has been safely deactivated.');
    }

    private function settingsFor(Request $request): UserSetting
    {
        $user = $request->user();

        return $user->setting()->firstOrCreate([
            'user_id' => $user->id,
        ])->load('user');
    }
}
