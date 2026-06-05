<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SavedPostApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_save_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Save this post',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/save")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Post saved successfully')
            ->assertJsonPath('data.post_id', $post->id)
            ->assertJsonPath('data.saved_by_me', true)
            ->assertJsonPath('data.saves_count', 1);

        $this->assertDatabaseHas('saved_posts', [
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);
    }

    public function test_duplicate_saves_are_prevented(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Only save once',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/save")->assertOk();

        $this->postJson("/api/posts/{$post->id}/save")
            ->assertOk()
            ->assertJsonPath('message', 'Post already saved')
            ->assertJsonPath('data.saves_count', 1);

        $this->assertDatabaseCount('saved_posts', 1);
    }

    public function test_authenticated_user_can_unsave_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Remove saved post',
        ]);

        $user->savedPosts()->create(['post_id' => $post->id]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/posts/{$post->id}/save")
            ->assertOk()
            ->assertJsonPath('message', 'Post removed from saved posts')
            ->assertJsonPath('data.saved_by_me', false)
            ->assertJsonPath('data.saves_count', 0);

        $this->assertDatabaseMissing('saved_posts', [
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);
    }

    public function test_unsave_works_when_post_was_not_saved(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Not saved yet',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/posts/{$post->id}/save")
            ->assertOk()
            ->assertJsonPath('message', 'Post was not saved')
            ->assertJsonPath('data.saved_by_me', false)
            ->assertJsonPath('data.saves_count', 0);
    }

    public function test_authenticated_user_can_list_saved_posts(): void
    {
        $user = User::factory()->create();
        $author = User::factory()->create();
        $saved = Post::query()->create([
            'user_id' => $author->id,
            'content' => 'Saved item',
        ]);
        $notSaved = Post::query()->create([
            'user_id' => $author->id,
            'content' => 'Not saved item',
        ]);

        $user->savedPosts()->create(['post_id' => $saved->id]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/saved-posts')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Saved posts fetched successfully')
            ->assertJsonPath('data.data.0.id', $saved->id)
            ->assertJsonPath('data.data.0.saved_by_me', true)
            ->assertJsonPath('data.data.0.saves_count', 1);

        $postIds = collect($response->json('data.data'))->pluck('id');

        $this->assertTrue($postIds->contains($saved->id));
        $this->assertFalse($postIds->contains($notSaved->id));
    }

    public function test_guest_cannot_save_posts(): void
    {
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Guest cannot save',
        ]);

        $this->postJson("/api/posts/{$post->id}/save")
            ->assertUnauthorized();
    }

    public function test_guest_cannot_view_saved_posts(): void
    {
        $this->getJson('/api/saved-posts')
            ->assertUnauthorized();
    }

    public function test_post_feed_response_includes_saved_fields(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Feed saved metadata',
        ]);

        $user->savedPosts()->create(['post_id' => $post->id]);

        Sanctum::actingAs($user);

        $this->getJson('/api/posts')
            ->assertOk()
            ->assertJsonPath('data.data.0.saved_by_me', true)
            ->assertJsonPath('data.data.0.saves_count', 1);
    }
}
