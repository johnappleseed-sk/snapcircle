<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SettingsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_fetch_settings(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/settings')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.settings.allow_messages', true)
            ->assertJsonPath('data.settings.show_email', false)
            ->assertJsonPath('data.settings.push_notifications_enabled', true)
            ->assertJsonPath('data.settings.account_status', 'active');
    }

    public function test_default_settings_are_created_if_missing(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->assertDatabaseMissing('user_settings', ['user_id' => $user->id]);

        $this->getJson('/api/settings')->assertOk();

        $this->assertDatabaseHas('user_settings', [
            'user_id' => $user->id,
            'allow_messages' => true,
            'show_email' => false,
        ]);
    }

    public function test_authenticated_user_can_update_settings(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->putJson('/api/settings', [
            'allow_messages' => false,
            'show_email' => true,
            'push_notifications_enabled' => false,
            'email_notifications_enabled' => true,
            'marketing_emails_enabled' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.settings.allow_messages', false)
            ->assertJsonPath('data.settings.show_email', true)
            ->assertJsonPath('data.settings.push_notifications_enabled', false)
            ->assertJsonPath('data.settings.email_notifications_enabled', true)
            ->assertJsonPath('data.settings.marketing_emails_enabled', true);
    }

    public function test_partial_settings_update_preserves_existing_values(): void
    {
        $user = User::factory()->create();
        UserSetting::query()->create([
            'user_id' => $user->id,
            'allow_messages' => false,
            'show_email' => true,
            'push_notifications_enabled' => true,
            'email_notifications_enabled' => false,
            'marketing_emails_enabled' => false,
        ]);
        Sanctum::actingAs($user);

        $this->putJson('/api/settings', [
            'push_notifications_enabled' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.settings.allow_messages', false)
            ->assertJsonPath('data.settings.show_email', true)
            ->assertJsonPath('data.settings.push_notifications_enabled', false);
    }

    public function test_guest_cannot_fetch_or_update_settings(): void
    {
        $this->getJson('/api/settings')->assertUnauthorized();
        $this->putJson('/api/settings', ['allow_messages' => false])->assertUnauthorized();
    }

    public function test_authenticated_user_can_deactivate_account(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token');
        Sanctum::actingAs($user, ['*']);

        $this->putJson('/api/account/deactivate')
            ->assertOk()
            ->assertJsonPath('message', 'Account deactivated successfully');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_status' => 'deactivated',
        ]);
        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $token->accessToken->id,
        ]);
    }

    public function test_delete_account_endpoint_safely_deactivates_account(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->deleteJson('/api/account')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'account_status' => 'deactivated',
        ]);
    }

    public function test_settings_response_does_not_expose_sensitive_fields(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/settings')
            ->assertOk()
            ->assertJsonMissingPath('data.settings.password')
            ->assertJsonMissingPath('data.settings.remember_token')
            ->assertJsonMissingPath('data.settings.tokens');
    }
}
