<?php

namespace Tests\Feature;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeviceTokenApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_register_android_device_token(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson('/api/device-tokens', [
            'token' => 'fcm-token-123',
            'platform' => 'android',
            'device_name' => 'Android emulator',
        ])
            ->assertCreated()
            ->assertJsonPath('message', 'Device token registered successfully')
            ->assertJsonPath('data.device_token.platform', 'android');

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $user->id,
            'token' => 'fcm-token-123',
            'platform' => 'android',
            'device_name' => 'Android emulator',
        ]);
    }

    public function test_registering_existing_token_moves_it_to_current_user(): void
    {
        $oldUser = User::factory()->create();
        $newUser = User::factory()->create();
        DeviceToken::query()->create([
            'user_id' => $oldUser->id,
            'token' => 'shared-fcm-token',
            'platform' => 'android',
        ]);

        Sanctum::actingAs($newUser);

        $this->postJson('/api/device-tokens', [
            'token' => 'shared-fcm-token',
            'platform' => 'android',
        ])->assertOk();

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $newUser->id,
            'token' => 'shared-fcm-token',
        ]);
        $this->assertSame(1, DeviceToken::query()->where('token', 'shared-fcm-token')->count());
    }

    public function test_authenticated_user_can_remove_their_device_token(): void
    {
        $user = User::factory()->create();
        DeviceToken::query()->create([
            'user_id' => $user->id,
            'token' => 'remove-me',
            'platform' => 'android',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/device-tokens', [
            'token' => 'remove-me',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Device token removed successfully');

        $this->assertDatabaseMissing('device_tokens', [
            'token' => 'remove-me',
        ]);
    }

    public function test_guest_cannot_manage_device_tokens(): void
    {
        $this->postJson('/api/device-tokens', [
            'token' => 'guest-token',
            'platform' => 'android',
        ])->assertUnauthorized();

        $this->deleteJson('/api/device-tokens', [
            'token' => 'guest-token',
        ])->assertUnauthorized();
    }
}
