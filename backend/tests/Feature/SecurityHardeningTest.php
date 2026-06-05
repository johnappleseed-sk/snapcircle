<?php

namespace Tests\Feature;

use App\Models\Comment;
use App\Models\Conversation;
use App\Models\Notification;
use App\Models\Post;
use App\Models\Story;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SecurityHardeningTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_user_cannot_access_protected_endpoint(): void
    {
        $this->getJson('/api/posts')
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Unauthenticated');
    }

    public function test_user_cannot_update_or_delete_another_users_post(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Private ownership check',
        ]);

        Sanctum::actingAs($other);

        $this->putJson("/api/posts/{$post->id}", ['content' => 'Nope'])
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');

        $this->deleteJson("/api/posts/{$post->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');
    }

    public function test_user_cannot_update_or_delete_another_users_comment(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Post',
        ]);
        $comment = Comment::query()->create([
            'user_id' => $owner->id,
            'post_id' => $post->id,
            'comment' => 'Comment',
        ]);

        Sanctum::actingAs($other);

        $this->putJson("/api/comments/{$comment->id}", ['comment' => 'Nope'])
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');

        $this->deleteJson("/api/comments/{$comment->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');
    }

    public function test_user_cannot_delete_another_users_story(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $story = Story::query()->create([
            'user_id' => $owner->id,
            'media_path' => 'stories/story.jpg',
            'caption' => 'Story',
            'expires_at' => now()->addDay(),
        ]);

        Sanctum::actingAs($other);

        $this->deleteJson("/api/stories/{$story->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');
    }

    public function test_user_cannot_access_another_users_conversation(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $conversation = Conversation::query()->create();
        $conversation->users()->attach([$owner->id]);

        Sanctum::actingAs($other);

        $this->getJson("/api/conversations/{$conversation->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');
    }

    public function test_user_cannot_modify_another_users_notification(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $notification = Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $other->id,
            'type' => Notification::TYPE_USER_FOLLOWED,
            'data' => ['message' => 'Followed'],
        ]);

        Sanctum::actingAs($other);

        $this->putJson("/api/notifications/{$notification->id}/read")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');

        $this->deleteJson("/api/notifications/{$notification->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');
    }

    public function test_user_resource_does_not_expose_sensitive_fields(): void
    {
        $user = User::factory()->create([
            'provider_id' => 'secret-provider-id',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/profile')
            ->assertOk()
            ->assertJsonMissingPath('data.user.password')
            ->assertJsonMissingPath('data.user.remember_token')
            ->assertJsonMissingPath('data.user.provider_id')
            ->assertJsonMissingPath('data.user.tokens');
    }

    public function test_invalid_image_upload_is_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->post('/api/posts', [
            'image' => UploadedFile::fake()->create('payload.txt', 12, 'text/plain'),
        ])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');
    }

    public function test_oversized_image_upload_is_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->post('/api/posts', [
            'image' => UploadedFile::fake()->create('large.jpg', 5000, 'image/jpeg'),
        ])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');
    }

    public function test_auth_rate_limit_returns_readable_message(): void
    {
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/auth/google', ['access_token' => 'invalid-token']);
        }

        $this->postJson('/api/auth/google', ['access_token' => 'invalid-token'])
            ->assertStatus(429)
            ->assertJsonPath('message', 'Too many requests. Please try again later.');
    }

    public function test_deactivated_user_cannot_access_active_account_routes(): void
    {
        Sanctum::actingAs(User::factory()->create([
            'account_status' => 'deactivated',
        ]));

        $this->getJson('/api/posts')
            ->assertForbidden()
            ->assertJsonPath('message', 'Your account is not active.');
    }
}
