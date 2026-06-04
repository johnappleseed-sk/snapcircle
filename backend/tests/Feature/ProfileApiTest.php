<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
