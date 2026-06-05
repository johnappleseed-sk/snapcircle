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
            ->assertJsonPath('data.data.0.content', 'Hello from SnapCircle')
            ->assertJsonPath('data.data.0.likes_count', 0)
            ->assertJsonPath('data.data.0.comments_count', 0)
            ->assertJsonPath('data.data.0.liked_by_me', false)
            ->assertJsonPath('data.data.0.is_owner', true)
            ->assertJsonPath('data.data.0.can_update', true)
            ->assertJsonPath('data.data.0.can_delete', true);
    }

    public function test_authenticated_user_can_fetch_following_feed(): void
    {
        $viewer = User::factory()->create();
        $followed = User::factory()->create();
        $stranger = User::factory()->create();

        $viewer->following()->attach($followed->id);

        Post::query()->create(['user_id' => $followed->id, 'content' => 'Followed post']);
        Post::query()->create(['user_id' => $viewer->id, 'content' => 'My own post']);
        Post::query()->create(['user_id' => $stranger->id, 'content' => 'Stranger post']);

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/posts?mode=following')
            ->assertOk()
            ->assertJsonPath('success', true);

        $contents = collect($response->json('data.data'))->pluck('content');

        $this->assertTrue($contents->contains('Followed post'));
        $this->assertTrue($contents->contains('My own post'));
        $this->assertFalse($contents->contains('Stranger post'));
    }

    public function test_authenticated_user_can_fetch_popular_feed(): void
    {
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $liker = User::factory()->create();

        $popular = Post::query()->create(['user_id' => $author->id, 'content' => 'Popular post']);
        $quiet = Post::query()->create(['user_id' => $author->id, 'content' => 'Quiet post']);

        $popular->likes()->create(['user_id' => $liker->id]);
        $popular->comments()->create(['user_id' => $liker->id, 'comment' => 'Nice']);

        Sanctum::actingAs($viewer);

        $this->getJson('/api/posts?mode=popular')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $popular->id)
            ->assertJsonPath('data.data.1.id', $quiet->id);
    }

    public function test_authenticated_user_can_fetch_own_posts(): void
    {
        $viewer = User::factory()->create();
        $other = User::factory()->create();

        Post::query()->create(['user_id' => $viewer->id, 'content' => 'Mine']);
        Post::query()->create(['user_id' => $other->id, 'content' => 'Not mine']);

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/posts?mode=mine')
            ->assertOk();

        $contents = collect($response->json('data.data'))->pluck('content');

        $this->assertTrue($contents->contains('Mine'));
        $this->assertFalse($contents->contains('Not mine'));
    }

    public function test_search_query_filters_posts(): void
    {
        $user = User::factory()->create();

        Post::query()->create(['user_id' => $user->id, 'content' => 'Laravel feed improvements']);
        Post::query()->create(['user_id' => $user->id, 'content' => 'Flutter profile polish']);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/posts?search=Laravel')
            ->assertOk();

        $contents = collect($response->json('data.data'))->pluck('content');

        $this->assertTrue($contents->contains('Laravel feed improvements'));
        $this->assertFalse($contents->contains('Flutter profile polish'));
    }

    public function test_guest_cannot_access_feed(): void
    {
        $this->getJson('/api/posts')
            ->assertUnauthorized();
    }

    public function test_post_detail_returns_expected_structure(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Detailed post',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/posts/{$post->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.post.id', $post->id)
            ->assertJsonPath('data.post.content', 'Detailed post')
            ->assertJsonPath('data.post.likes_count', 0)
            ->assertJsonPath('data.post.comments_count', 0)
            ->assertJsonPath('data.post.liked_by_me', false)
            ->assertJsonPath('data.post.is_owner', true)
            ->assertJsonPath('data.post.can_update', true)
            ->assertJsonPath('data.post.can_delete', true)
            ->assertJsonStructure([
                'data' => [
                    'post' => [
                        'user' => ['id', 'name', 'email'],
                    ],
                ],
            ]);
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
