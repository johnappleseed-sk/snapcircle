<?php

namespace Tests\Feature;

use App\Models\Follow;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SafetyModerationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_block_and_unblock_another_user(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();
        Follow::query()->create([
            'follower_id' => $user->id,
            'following_id' => $target->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$target->id}/block")
            ->assertCreated()
            ->assertJsonPath('data.is_blocked_by_me', true)
            ->assertJsonPath('data.user.is_blocked_by_me', true);

        $this->assertDatabaseHas('user_blocks', [
            'blocker_id' => $user->id,
            'blocked_id' => $target->id,
        ]);
        $this->assertDatabaseMissing('follows', [
            'follower_id' => $user->id,
            'following_id' => $target->id,
        ]);

        $this->deleteJson("/api/users/{$target->id}/block")
            ->assertOk()
            ->assertJsonPath('data.is_blocked_by_me', false);

        $this->assertDatabaseMissing('user_blocks', [
            'blocker_id' => $user->id,
            'blocked_id' => $target->id,
        ]);
    }

    public function test_user_cannot_block_themselves(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$user->id}/block")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You cannot block yourself.');
    }

    public function test_blocked_user_posts_are_hidden_from_feed(): void
    {
        $user = User::factory()->create();
        $blocked = User::factory()->create();
        $visible = User::factory()->create();
        $blockedPost = Post::query()->create([
            'user_id' => $blocked->id,
            'content' => 'Hidden post',
        ]);
        $visiblePost = Post::query()->create([
            'user_id' => $visible->id,
            'content' => 'Visible post',
        ]);
        UserBlock::query()->create([
            'blocker_id' => $user->id,
            'blocked_id' => $blocked->id,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/posts')
            ->assertOk()
            ->assertJsonMissing(['id' => $blockedPost->id])
            ->assertJsonFragment(['id' => $visiblePost->id]);
    }

    public function test_blocked_users_cannot_follow_or_start_conversation(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();
        UserBlock::query()->create([
            'blocker_id' => $user->id,
            'blocked_id' => $target->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$target->id}/follow")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You cannot follow this user.');

        $this->postJson('/api/conversations', ['user_id' => $target->id])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You cannot message this user.');
    }

    public function test_user_can_report_post_with_new_reason_and_cannot_duplicate_pending_report(): void
    {
        $reporter = User::factory()->create();
        $owner = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Reportable post',
        ]);

        Sanctum::actingAs($reporter);

        $this->postJson("/api/posts/{$post->id}/report", [
            'reason' => Report::REASON_HATE,
            'description' => 'This needs review.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.report.reason', Report::REASON_HATE);

        $this->postJson("/api/posts/{$post->id}/report", [
            'reason' => Report::REASON_HATE,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You already have a pending report for this item.');
    }

    public function test_admin_can_update_report_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $reporter = User::factory()->create();
        $owner = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Reported post',
        ]);
        $report = Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => Report::REASON_SPAM,
        ]);

        Sanctum::actingAs($admin);

        $this->putJson("/api/admin/reports/{$report->id}/status", [
            'status' => Report::STATUS_ACTION_TAKEN,
            'action_taken' => 'Content removed.',
        ])
            ->assertOk()
            ->assertJsonPath('data.report.status', Report::STATUS_ACTION_TAKEN)
            ->assertJsonPath('data.report.action_taken', 'Content removed.');
    }
}
