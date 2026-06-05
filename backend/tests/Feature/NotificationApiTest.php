<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_receives_notification_when_another_user_likes_their_post(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();

        Sanctum::actingAs($actor);

        $this->postJson("/api/posts/{$post->id}/like")->assertOk();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);
    }

    public function test_user_receives_notification_when_another_user_comments_on_their_post(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();

        Sanctum::actingAs($actor);

        $this->postJson("/api/posts/{$post->id}/comments", [
            'comment' => 'Nice post!',
        ])->assertCreated();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_COMMENTED,
            'post_id' => $post->id,
        ]);
    }

    public function test_user_receives_notification_when_another_user_follows_them(): void
    {
        $followed = User::factory()->create();
        $actor = User::factory()->create();

        Sanctum::actingAs($actor);

        $this->postJson("/api/users/{$followed->id}/follow")->assertOk();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $followed->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_USER_FOLLOWED,
        ]);
    }

    public function test_user_does_not_receive_notifications_for_self_actions(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Self action post',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/like")->assertOk();
        $this->postJson("/api/posts/{$post->id}/comments", [
            'comment' => 'My own comment',
        ])->assertCreated();
        $this->postJson("/api/users/{$user->id}/follow")->assertUnprocessable();

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_authenticated_user_can_list_their_notifications(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        $notification = Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
            'data' => ['actor_name' => $actor->name],
        ]);

        Sanctum::actingAs($owner);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.data.0.id', $notification->id)
            ->assertJsonPath('data.data.0.type', Notification::TYPE_POST_LIKED)
            ->assertJsonPath('data.data.0.is_read', false);
    }

    public function test_user_cannot_mark_another_users_notification_as_read(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        $notification = Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($actor);

        $this->putJson("/api/notifications/{$notification->id}/read")
            ->assertForbidden();
    }

    public function test_unread_count_works(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);
        Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_COMMENTED,
            'post_id' => $post->id,
            'read_at' => now(),
        ]);

        Sanctum::actingAs($owner);

        $this->getJson('/api/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1);
    }

    public function test_mark_single_notification_as_read_works(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        $notification = Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($owner);

        $this->putJson("/api/notifications/{$notification->id}/read")
            ->assertOk()
            ->assertJsonPath('data.notification.is_read', true);

        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_mark_all_notifications_as_read_works(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);
        Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_COMMENTED,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($owner);

        $this->putJson('/api/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('data.updated_count', 2);

        $this->assertSame(0, Notification::query()->whereNull('read_at')->count());
    }

    public function test_delete_own_notification_works(): void
    {
        [$owner, $actor, $post] = $this->usersAndPost();
        $notification = Notification::query()->create([
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
            'post_id' => $post->id,
        ]);

        Sanctum::actingAs($owner);

        $this->deleteJson("/api/notifications/{$notification->id}")
            ->assertOk();

        $this->assertDatabaseMissing('notifications', ['id' => $notification->id]);
    }

    public function test_guest_cannot_access_notification_routes(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
        $this->getJson('/api/notifications/unread-count')->assertUnauthorized();
    }

    /**
     * @return array{0: User, 1: User, 2: Post}
     */
    private function usersAndPost(): array
    {
        $owner = User::factory()->create();
        $actor = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Notification post',
        ]);

        return [$owner, $actor, $post];
    }
}
