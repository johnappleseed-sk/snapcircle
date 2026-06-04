<?php

namespace Tests\Feature;

use App\Models\Like;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LikeApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_like_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Likeable post',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('message', 'Post liked successfully')
            ->assertJsonPath('data.likes_count', 1)
            ->assertJsonPath('data.liked_by_me', true);

        $this->assertDatabaseHas('likes', [
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);
    }

    public function test_duplicate_likes_are_prevented(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Already liked post',
        ]);
        Like::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('message', 'Post already liked')
            ->assertJsonPath('data.likes_count', 1)
            ->assertJsonPath('data.liked_by_me', true);

        $this->assertSame(1, Like::query()->where('post_id', $post->id)->count());
    }

    public function test_user_can_unlike_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Unlikeable post',
        ]);
        Like::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/posts/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('message', 'Post unliked successfully')
            ->assertJsonPath('data.likes_count', 0)
            ->assertJsonPath('data.liked_by_me', false);

        $this->assertDatabaseMissing('likes', [
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);
    }
}
