<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class PushNotificationService
{
    public function sendToUser(User $user, string $title, string $body, string $type, array $data = []): void
    {
        if (! $this->canSendTo($user)) {
            return;
        }

        $tokens = $user->deviceTokens()
            ->where('platform', 'android')
            ->pluck('token');

        if ($tokens->isEmpty()) {
            return;
        }

        $accessToken = $this->accessToken();
        $projectId = config('services.firebase.project_id');

        if (! $accessToken || ! $projectId) {
            Log::debug('Skipping push notification because Firebase is not configured.', [
                'user_id' => $user->id,
                'type' => $type,
            ]);

            return;
        }

        foreach ($tokens as $token) {
            $this->sendToToken((string) $token, $accessToken, $projectId, $title, $body, $type, $data);
        }
    }

    private function canSendTo(User $user): bool
    {
        $settings = $user->setting;

        return (bool) ($settings?->push_notifications_enabled ?? true);
    }

    private function sendToToken(
        string $token,
        string $accessToken,
        string $projectId,
        string $title,
        string $body,
        string $type,
        array $data
    ): void {
        try {
            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $this->stringData([
                        ...$data,
                        'type' => $type,
                    ]),
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'channel_id' => 'snapcircle_activity',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        ],
                    ],
                ],
            ];

            $response = Http::withToken($accessToken)
                ->acceptJson()
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", $payload);

            if ($response->successful()) {
                DeviceToken::query()
                    ->where('token', $token)
                    ->update(['last_used_at' => now()]);

                return;
            }

            if (in_array($response->status(), [400, 404], true)) {
                DeviceToken::query()->where('token', $token)->delete();
            }

            Log::warning('Firebase push notification failed.', [
                'status' => $response->status(),
                'body' => Str::limit($response->body(), 500),
            ]);
        } catch (Throwable $exception) {
            Log::warning('Firebase push notification exception.', [
                'message' => $exception->getMessage(),
            ]);
        }
    }

    private function accessToken(): ?string
    {
        return Cache::remember('firebase_access_token', now()->addMinutes(50), function (): ?string {
            $credentials = $this->serviceAccount();

            if (! $credentials) {
                return null;
            }

            try {
                $now = time();
                $jwt = $this->jwt([
                    'iss' => $credentials['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'iat' => $now,
                    'exp' => $now + 3600,
                ], $credentials['private_key']);

                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if (! $response->successful()) {
                    Log::warning('Unable to obtain Firebase access token.', [
                        'status' => $response->status(),
                        'body' => Str::limit($response->body(), 500),
                    ]);

                    return null;
                }

                return $response->json('access_token');
            } catch (Throwable $exception) {
                Log::warning('Firebase access token exception.', [
                    'message' => $exception->getMessage(),
                ]);

                return null;
            }
        });
    }

    private function serviceAccount(): ?array
    {
        $path = config('services.firebase.service_account_path');

        if (! $path || ! is_readable($path)) {
            return null;
        }

        $credentials = json_decode((string) file_get_contents($path), true);

        if (
            ! is_array($credentials) ||
            empty($credentials['client_email']) ||
            empty($credentials['private_key'])
        ) {
            return null;
        }

        return $credentials;
    }

    private function jwt(array $claims, string $privateKey): string
    {
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $segments = [
            $this->base64Url(json_encode($header, JSON_THROW_ON_ERROR)),
            $this->base64Url(json_encode($claims, JSON_THROW_ON_ERROR)),
        ];
        $unsigned = implode('.', $segments);

        if (! openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
            throw new \RuntimeException('Unable to sign Firebase service account JWT.');
        }

        $segments[] = $this->base64Url($signature);

        return implode('.', $segments);
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function stringData(array $data): array
    {
        return collect($data)
            ->filter(fn ($value) => $value !== null)
            ->mapWithKeys(fn ($value, string $key) => [$key => (string) $value])
            ->all();
    }
}
