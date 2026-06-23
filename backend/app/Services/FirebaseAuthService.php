<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use RuntimeException;
use Throwable;

class FirebaseAuthService
{
    /**
     * @return array<string, mixed>
     */
    public function verifyIdToken(string $idToken): array
    {
        $projectId = config('services.firebase.project_id');

        if (! is_string($projectId) || $projectId === '') {
            throw new RuntimeException('Firebase project ID is not configured.');
        }

        $decoded = $this->decodeWithGoogleCertificates($idToken);
        $claims = json_decode(json_encode($decoded, JSON_THROW_ON_ERROR), true, 512, JSON_THROW_ON_ERROR);

        if (($claims['aud'] ?? null) !== $projectId) {
            throw new RuntimeException('Firebase token audience is invalid.');
        }

        if (($claims['iss'] ?? null) !== "https://securetoken.google.com/{$projectId}") {
            throw new RuntimeException('Firebase token issuer is invalid.');
        }

        if (! is_string($claims['sub'] ?? null) || trim($claims['sub']) === '') {
            throw new RuntimeException('Firebase token subject is missing.');
        }

        return $claims;
    }

    private function decodeWithGoogleCertificates(string $idToken): object
    {
        $certificates = $this->certificates();
        $lastException = null;

        foreach ($certificates as $keyId => $certificate) {
            try {
                return JWT::decode($idToken, new Key((string) $certificate, 'RS256'));
            } catch (Throwable $exception) {
                $lastException = $exception;
            }
        }

        throw new RuntimeException(
            'Firebase ID token could not be verified: '.Str::limit($lastException?->getMessage() ?? 'unknown error', 160)
        );
    }

    /**
     * @return array<string, string>
     */
    private function certificates(): array
    {
        return Cache::remember('firebase_auth_certificates', now()->addHours(6), function (): array {
            $response = Http::acceptJson()
                ->timeout(10)
                ->get('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');

            if (! $response->successful()) {
                throw new RuntimeException('Unable to fetch Firebase auth certificates.');
            }

            $certificates = $response->json();

            if (! is_array($certificates) || $certificates === []) {
                throw new RuntimeException('Firebase auth certificates response was empty.');
            }

            return $certificates;
        });
    }
}
