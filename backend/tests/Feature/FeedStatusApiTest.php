<?php

namespace Tests\Feature;

use App\Models\Comment;
use App\Models\Notification;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FeedStatusApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_fetch_feed_status(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Latest feed status post',
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/feed/status')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.latest_post_id', $post->id)
            ->assertJsonPath('data.total_posts_count', 1)
            ->assertJsonPath('data.unread_notifications_count', 0);
    }

    public function test_guest_cannot_fetch_feed_status(): void
    {
        $this->getJson('/api/feed/status')->assertUnauthorized();
    }

    public function test_feed_status_includes_unread_notification_count(): void
    {
        $user = User::factory()->create();
        $actor = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $actor->id,
            'content' => 'Notification source',
        ]);

        Notification::query()->create([
            'user_id' => $user->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);
        Notification::query()->create([
            'user_id' => $user->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_COMMENTED,
            'post_id' => $post->id,
            'read_at' => now(),
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/feed/status')
            ->assertOk()
            ->assertJsonPath('data.unread_notifications_count', 1);
    }

    public function test_authenticated_user_can_fetch_comments_status(): void
    {
        [$user, $post] = $this->userAndPost();
        $latestComment = Comment::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'Latest comment',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/posts/{$post->id}/comments/status")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.post_id', $post->id)
            ->assertJsonPath('data.latest_comment_id', $latestComment->id)
            ->assertJsonPath('data.comments_count', 1);
    }

    public function test_guest_cannot_fetch_comments_status(): void
    {
        [$user, $post] = $this->userAndPost();

        $this->getJson("/api/posts/{$post->id}/comments/status")->assertUnauthorized();
    }

    public function test_comments_status_includes_comments_count(): void
    {
        [$user, $post] = $this->userAndPost();

        Comment::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'First comment',
        ]);
        Comment::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'Second comment',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/posts/{$post->id}/comments/status")
            ->assertOk()
            ->assertJsonPath('data.comments_count', 2);
    }

    /**
     * @return array{0: User, 1: Post}
     */
    private function userAndPost(): array
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Post with comments',
        ]);

        return [$user, $post];
    }
}
