<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PostApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_list_posts(): void
    {
        $user = User::factory()->create();
        Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Hello from SnapCircle',
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/posts')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.posts.0.content', 'Hello from SnapCircle')
            ->assertJsonPath('data.posts.0.likes_count', 0)
            ->assertJsonPath('data.posts.0.comments_count', 0)
            ->assertJsonPath('data.posts.0.liked_by_me', false);
    }

    public function test_authenticated_user_can_create_text_post(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson('/api/posts', [
            'content' => 'A clean text-only post.',
        ])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.post.content', 'A clean text-only post.');

        $this->assertDatabaseHas('posts', [
            'user_id' => $user->id,
            'content' => 'A clean text-only post.',
        ]);
    }

    public function test_guest_cannot_create_post(): void
    {
        $this->postJson('/api/posts', [
            'content' => 'Guests should not post.',
        ])
            ->assertUnauthorized();
    }

    public function test_user_cannot_update_another_users_post(): void
    {
        $owner = User::factory()->create();
        $otherUser = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Original content',
        ]);

        Sanctum::actingAs($otherUser);

        $this->putJson("/api/posts/{$post->id}", [
            'content' => 'Attempted update',
        ])
            ->assertForbidden()
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('posts', [
            'id' => $post->id,
            'content' => 'Original content',
        ]);
    }

    public function test_user_can_delete_own_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Delete my own post',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/posts/{$post->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Post deleted');

        $this->assertSoftDeleted('posts', [
            'id' => $post->id,
        ]);
    }
}
