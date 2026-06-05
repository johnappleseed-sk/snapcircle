<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_view_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Maya Sok',
            'bio' => 'Demo profile',
        ]);
        Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Profile post',
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/profile')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.name', 'Maya Sok')
            ->assertJsonPath('data.user.bio', 'Demo profile')
            ->assertJsonPath('data.user.posts_count', 1)
            ->assertJsonPath('data.user.followers_count', 0)
            ->assertJsonPath('data.user.following_count', 0);
    }

    public function test_authenticated_user_can_update_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Old Name',
            'bio' => 'Old bio',
        ]);

        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'New Name',
            'bio' => 'Updated profile bio',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Profile updated successfully')
            ->assertJsonPath('data.user.name', 'New Name')
            ->assertJsonPath('data.user.bio', 'Updated profile bio');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'New Name',
            'bio' => 'Updated profile bio',
        ]);
    }

    public function test_authenticated_user_can_update_username_location_and_website(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'Maya Sok',
            'username' => 'maya.sok',
            'bio' => 'Updated profile bio',
            'location' => 'Phnom Penh',
            'website' => 'https://snapcircle.test',
            'is_private' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.user.username', 'maya.sok')
            ->assertJsonPath('data.user.location', 'Phnom Penh')
            ->assertJsonPath('data.user.website', 'https://snapcircle.test')
            ->assertJsonPath('data.user.is_private', true);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'username' => 'maya.sok',
            'location' => 'Phnom Penh',
            'website' => 'https://snapcircle.test',
            'is_private' => true,
        ]);
    }

    public function test_username_must_be_unique(): void
    {
        User::factory()->create(['username' => 'taken_name']);
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'Maya Sok',
            'username' => 'taken_name',
        ])->assertUnprocessable();
    }

    public function test_username_cannot_contain_spaces(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'Maya Sok',
            'username' => 'bad name',
        ])->assertUnprocessable();
    }

    public function test_authenticated_user_can_update_avatar_and_cover_image(): void
    {
        Storage::fake('public');
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->put('/api/profile', [
            'name' => 'Maya Sok',
            'avatar' => UploadedFile::fake()->image('avatar.png'),
            'cover_image' => UploadedFile::fake()->image('cover.jpg', 1200, 600),
        ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $user->refresh();

        $this->assertNotNull($user->avatar);
        $this->assertNotNull($user->cover_image);
        Storage::disk('public')->assertExists($user->avatar);
        Storage::disk('public')->assertExists($user->cover_image);
    }

    public function test_user_resource_includes_profile_improvement_fields_without_sensitive_fields(): void
    {
        $user = User::factory()->create([
            'username' => 'lina',
            'cover_image' => 'covers/lina.jpg',
            'location' => 'Siem Reap',
            'website' => 'https://lina.test',
            'is_private' => false,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/profile')
            ->assertOk()
            ->assertJsonPath('data.user.username', 'lina')
            ->assertJsonPath('data.user.cover_image', 'covers/lina.jpg')
            ->assertJsonPath('data.user.location', 'Siem Reap')
            ->assertJsonPath('data.user.website', 'https://lina.test')
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'avatar_url',
                        'cover_image_url',
                        'joined_at',
                        'last_active_at',
                        'profile_completion',
                        'is_me',
                    ],
                ],
            ])
            ->assertJsonMissingPath('data.user.password')
            ->assertJsonMissingPath('data.user.provider_id')
            ->assertJsonMissingPath('data.user.remember_token');
    }

    public function test_user_can_be_fetched_by_username(): void
    {
        $authUser = User::factory()->create();
        User::factory()->create([
            'name' => 'Dara Chen',
            'username' => 'dara',
        ]);

        Sanctum::actingAs($authUser);

        $this->getJson('/api/users/username/dara')
            ->assertOk()
            ->assertJsonPath('data.user.name', 'Dara Chen')
            ->assertJsonPath('data.user.username', 'dara');
    }

    public function test_user_posts_endpoint_returns_posts(): void
    {
        $authUser = User::factory()->create();
        $profileUser = User::factory()->create();
        Post::query()->create([
            'user_id' => $profileUser->id,
            'content' => 'Profile post',
        ]);

        Sanctum::actingAs($authUser);

        $this->getJson("/api/users/{$profileUser->id}/posts")
            ->assertOk()
            ->assertJsonPath('data.posts.0.content', 'Profile post')
            ->assertJsonPath('data.posts.0.is_owner', false)
            ->assertJsonPath('data.meta.total', 1);
    }

    public function test_guest_cannot_update_profile(): void
    {
        $this->putJson('/api/profile', [
            'name' => 'Guest Update',
        ])->assertUnauthorized();
    }

    public function test_guest_cannot_view_profile(): void
    {
        $this->getJson('/api/profile')
            ->assertUnauthorized();
    }

    public function test_user_can_search_users(): void
    {
        $authUser = User::factory()->create(['name' => 'Current User']);
        User::factory()->create(['name' => 'Saturn Sky']);
        User::factory()->create(['name' => 'Moon River']);

        Sanctum::actingAs($authUser);

        $this->getJson('/api/users?search=saturn')
            ->assertOk()
            ->assertJsonPath('data.users.0.name', 'Saturn Sky')
            ->assertJsonPath('data.meta.total', 1);
    }
}
