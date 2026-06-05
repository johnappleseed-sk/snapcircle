<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Notification;
use App\Models\Post;
use App\Models\Story;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PerformanceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_posts_endpoint_paginates_and_caps_per_page(): void
    {
        $user = User::factory()->create();
        Post::query()->create(['user_id' => $user->id, 'content' => 'Fast feed']);

        Sanctum::actingAs($user);

        $this->getJson('/api/posts?per_page=1000')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonStructure([
                'data' => ['data', 'current_page', 'last_page', 'per_page', 'total'],
            ]);
    }

    public function test_explore_posts_response_structure_is_unchanged(): void
    {
        [$viewer, $author] = [User::factory()->create(), User::factory()->create()];
        $post = Post::query()->create(['user_id' => $author->id, 'content' => 'Explore performance']);

        Sanctum::actingAs($viewer);

        $this->getJson('/api/explore/posts?per_page=1000')
            ->assertOk()
            ->assertJsonPath('data.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonPath('data.data.0.id', $post->id)
            ->assertJsonStructure([
                'data' => [
                    'data' => [
                        '*' => ['id', 'content', 'likes_count', 'comments_count', 'saves_count', 'user'],
                    ],
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);
    }

    public function test_user_posts_endpoint_still_paginates(): void
    {
        [$viewer, $author] = [User::factory()->create(), User::factory()->create()];
        $post = Post::query()->create(['user_id' => $author->id, 'content' => 'Profile page post']);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/users/{$author->id}/posts?per_page=1000")
            ->assertOk()
            ->assertJsonPath('data.meta.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonPath('data.posts.0.id', $post->id);
    }

    public function test_notifications_endpoint_still_paginates(): void
    {
        [$user, $actor] = [User::factory()->create(), User::factory()->create()];
        $notification = Notification::query()->create([
            'user_id' => $user->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_USER_FOLLOWED,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/notifications?per_page=1000')
            ->assertOk()
            ->assertJsonPath('data.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonPath('data.data.0.id', $notification->id);
    }

    public function test_messages_endpoint_still_paginates(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = Conversation::query()->create();
        $conversation->users()->attach([$user->id, $other->id]);
        $message = $conversation->messages()->create([
            'sender_id' => $other->id,
            'message' => 'Paged message',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/conversations/{$conversation->id}/messages?per_page=1000")
            ->assertOk()
            ->assertJsonPath('data.meta.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonPath('data.messages.0.id', $message->id);
    }

    public function test_stories_endpoint_still_paginates(): void
    {
        $user = User::factory()->create();
        $story = Story::query()->create([
            'user_id' => $user->id,
            'media_path' => 'stories/performance.jpg',
            'expires_at' => now()->addDay(),
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/stories?per_page=1000')
            ->assertOk()
            ->assertJsonPath('data.per_page', config('snapcircle.pagination.max_per_page'))
            ->assertJsonPath('data.data.0.id', $story->id);
    }
}
