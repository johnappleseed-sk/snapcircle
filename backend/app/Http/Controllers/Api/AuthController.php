<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Helpers\ApiResponse;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;
use Laravel\Socialite\Facades\Socialite;
use Throwable;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::query()->create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'email_verified_at' => now(),
        ]);

        $token = $user->createToken('snapcircle-api-token')->plainTextToken;

        return ApiResponse::success('Registration successful', [
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = User::query()->where('email', $validated['email'])->first();

        if (! $user || ! $user->password || ! Hash::check($validated['password'], $user->password)) {
            return ApiResponse::error('The provided credentials are incorrect.', [], 401);
        }

        if ($user->account_status !== 'active') {
            return ApiResponse::error('This account is not active.', [], 403);
        }

        $token = $user->createToken('snapcircle-api-token')->plainTextToken;

        return ApiResponse::success('Login successful', [
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $status = Password::sendResetLink($request->only('email'));

        if ($status === Password::RESET_THROTTLED) {
            return ApiResponse::error('Please wait before requesting another password reset email.', [], 429);
        }

        return ApiResponse::success('If an account exists for that email, a password reset link has been sent.');
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return ApiResponse::error('The password reset token is invalid or has expired.', [], 422);
        }

        return ApiResponse::success('Password reset successful');
    }

    public function google(Request $request): JsonResponse
    {
        return $this->loginWithProvider($request, 'google');
    }

    public function facebook(Request $request): JsonResponse
    {
        return $this->loginWithProvider($request, 'facebook');
    }

    public function demo(): JsonResponse
    {
        if (! app()->isLocal()) {
            return ApiResponse::error('Demo login is only available locally', [], 403);
        }

        $user = User::query()->where('email', 'maya@snapcircle.local')->first()
            ?? User::query()->first();

        if (! $user) {
            return ApiResponse::error('No demo user is available. Run database seeders first.', [], 404);
        }

        if ($user->account_status !== 'active') {
            return ApiResponse::error('This account is not active.', [], 403);
        }

        $token = $user->createToken('snapcircle-demo-token')->plainTextToken;

        return ApiResponse::success('Demo login successful', [
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function user(Request $request): JsonResponse
    {
        if ($request->user()?->account_status !== 'active') {
            return ApiResponse::error('This account is not active.', [], 403);
        }

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
                if ($user->account_status !== 'active') {
                    return ApiResponse::error('This account is not active.', [], 403);
                }

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
