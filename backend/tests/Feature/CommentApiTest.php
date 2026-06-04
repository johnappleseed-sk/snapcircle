<?php

namespace Tests\Feature;

use App\Models\Comment;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CommentApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_comment_on_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Commentable post',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/posts/{$post->id}/comments", [
            'comment' => 'Nice post!',
        ])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.comment.comment', 'Nice post!')
            ->assertJsonPath('data.comments_count', 1);

        $this->assertDatabaseHas('comments', [
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'Nice post!',
        ]);
    }

    public function test_guest_cannot_comment_on_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Protected post',
        ]);

        $this->postJson("/api/posts/{$post->id}/comments", [
            'comment' => 'Guest comment',
        ])
            ->assertUnauthorized();
    }

    public function test_user_can_update_own_comment(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Original post',
        ]);
        $comment = Comment::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'Original comment',
        ]);

        Sanctum::actingAs($user);

        $this->putJson("/api/comments/{$comment->id}", [
            'comment' => 'Updated comment text',
        ])
            ->assertOk()
            ->assertJsonPath('data.comment.comment', 'Updated comment text');

        $this->assertDatabaseHas('comments', [
            'id' => $comment->id,
            'comment' => 'Updated comment text',
        ]);
    }

    public function test_user_cannot_update_another_users_comment(): void
    {
        $owner = User::factory()->create();
        $otherUser = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Original post',
        ]);
        $comment = Comment::query()->create([
            'user_id' => $owner->id,
            'post_id' => $post->id,
            'comment' => 'Original comment',
        ]);

        Sanctum::actingAs($otherUser);

        $this->putJson("/api/comments/{$comment->id}", [
            'comment' => 'Unauthorized edit',
        ])
            ->assertForbidden()
            ->assertJsonPath('message', 'Unauthorized action');

        $this->assertDatabaseHas('comments', [
            'id' => $comment->id,
            'comment' => 'Original comment',
        ]);
    }

    public function test_user_can_delete_own_comment(): void
    {
        $user = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $user->id,
            'content' => 'Original post',
        ]);
        $comment = Comment::query()->create([
            'user_id' => $user->id,
            'post_id' => $post->id,
            'comment' => 'Delete me',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/comments/{$comment->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Comment deleted successfully')
            ->assertJsonPath('data.comments_count', 0);

        $this->assertSoftDeleted('comments', [
            'id' => $comment->id,
        ]);
    }
}
