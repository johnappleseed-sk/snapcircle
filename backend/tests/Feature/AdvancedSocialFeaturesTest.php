<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\Post;
use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdvancedSocialFeaturesTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_collection_and_add_saved_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => User::factory()->create()->id,
            'content' => 'Collect this post #ideas',
        ]);
        Sanctum::actingAs($user);

        $collectionId = $this->postJson('/api/saved-collections', [
            'name' => 'Ideas',
        ])
            ->assertCreated()
            ->assertJsonPath('data.collection.name', 'Ideas')
            ->json('data.collection.id');

        $this->postJson("/api/saved-collections/{$collectionId}/posts/{$post->id}")
            ->assertOk()
            ->assertJsonPath('data.collection.posts_count', 1);

        $this->assertDatabaseHas('saved_posts', [
            'user_id' => $user->id,
            'post_id' => $post->id,
        ]);
        $this->assertDatabaseHas('saved_collection_posts', [
            'saved_collection_id' => $collectionId,
            'post_id' => $post->id,
        ]);

        $this->getJson("/api/saved-collections/{$collectionId}/posts")
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $post->id);
    }

    public function test_user_activity_returns_recent_sections(): void
    {
        $user = User::factory()->create();
        $author = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'My activity post',
        ]);
        $likedPost = Post::query()->create([
            'user_id' => $author->id,
            'content' => 'Liked post',
        ]);
        $user->likes()->create(['post_id' => $likedPost->id]);
        $user->savedPosts()->create(['post_id' => $likedPost->id]);
        $user->comments()->create([
            'post_id' => $likedPost->id,
            'comment' => 'Activity comment',
        ]);
        $user->following()->attach($author->id, ['status' => 'accepted']);

        Sanctum::actingAs($user);

        $this->getJson('/api/me/activity')
            ->assertOk()
            ->assertJsonPath('data.posts.0.id', $post->id)
            ->assertJsonPath('data.comments.0.comment', 'Activity comment')
            ->assertJsonPath('data.likes.0.id', $likedPost->id)
            ->assertJsonPath('data.saved.0.id', $likedPost->id)
            ->assertJsonPath('data.follows.0.user.id', $author->id);
    }

    public function test_notification_preferences_suppress_disabled_categories(): void
    {
        $owner = User::factory()->create();
        $actor = User::factory()->create();
        UserSetting::query()->create([
            'user_id' => $owner->id,
            'push_notifications_enabled' => true,
            'notify_likes' => false,
        ]);
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'No like notification',
        ]);

        Sanctum::actingAs($actor);

        $this->postJson("/api/posts/{$post->id}/like")->assertOk();

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $owner->id,
            'actor_id' => $actor->id,
            'type' => Notification::TYPE_POST_LIKED,
        ]);
    }
}
