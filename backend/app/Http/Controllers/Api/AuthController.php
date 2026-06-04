<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Laravel\Socialite\Facades\Socialite;
use Throwable;

class AuthController extends Controller
{
    public function google(Request $request): JsonResponse
    {
        return $this->loginWithProvider($request, 'google');
    }

    public function facebook(Request $request): JsonResponse
    {
        return $this->loginWithProvider($request, 'facebook');
    }

    public function user(Request $request): JsonResponse
    {
        return ApiResponse::success('Authenticated user retrieved', [
            'user' => $request->user(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return ApiResponse::success('Logout successful');
    }

    private function loginWithProvider(Request $request, string $provider): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'access_token' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation failed', $validator->errors()->toArray(), 422);
        }

        try {
            $socialUser = Socialite::driver($provider)
                ->stateless()
                ->userFromToken($request->string('access_token')->toString());

            $providerId = (string) $socialUser->getId();
            $email = $socialUser->getEmail();

            if (! $email) {
                return ApiResponse::error('Social account email is required', [], 422);
            }

            $user = User::query()
                ->where(function ($query) use ($provider, $providerId): void {
                    $query->where('provider', $provider)
                        ->where('provider_id', $providerId);
                })
                ->orWhere('email', $email)
                ->first();

            if ($user) {
                $user->update([
                    'name' => $socialUser->getName() ?: $user->name,
                    'email' => $email,
                    'avatar' => $socialUser->getAvatar(),
                    'provider' => $provider,
                    'provider_id' => $providerId,
                ]);
            } else {
                $user = User::query()->create([
                    'name' => $socialUser->getName() ?: $socialUser->getNickname() ?: 'SnapCircle User',
                    'email' => $email,
                    'avatar' => $socialUser->getAvatar(),
                    'provider' => $provider,
                    'provider_id' => $providerId,
                    'email_verified_at' => now(),
                ]);
            }

            $token = $user->createToken('snapcircle-api-token')->plainTextToken;

            return ApiResponse::success('Login successful', [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ]);
        } catch (Throwable) {
            return ApiResponse::error('Invalid social token', [], 401);
        }
    }
}
