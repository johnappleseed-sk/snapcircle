<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminModerationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_normal_user_cannot_access_admin_routes(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/dashboard')
            ->assertForbidden()
            ->assertJsonPath('message', 'Admin access required.');
    }

    public function test_admin_can_access_dashboard(): void
    {
        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'total_users',
                    'active_users',
                    'banned_users',
                    'total_posts',
                    'total_comments',
                    'total_reports',
                    'pending_reports',
                ],
            ]);
    }

    public function test_user_can_report_a_post(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        Sanctum::actingAs($reporter);

        $this->postJson("/api/posts/{$post->id}/report", [
            'reason' => Report::REASON_SPAM,
            'description' => 'This looks like spam.',
        ])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.report.reason', Report::REASON_SPAM)
            ->assertJsonPath('data.report.status', Report::STATUS_PENDING);

        $this->assertDatabaseHas('reports', [
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => Report::REASON_SPAM,
        ]);
    }

    public function test_duplicate_pending_report_is_prevented(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        Sanctum::actingAs($reporter);

        $payload = ['reason' => Report::REASON_SPAM];

        $this->postJson("/api/posts/{$post->id}/report", $payload)->assertCreated();
        $this->postJson("/api/posts/{$post->id}/report", $payload)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You already have a pending report for this item.');
    }

    public function test_admin_can_list_reports(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        $report = $this->reportFor($reporter, $post);

        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/reports')
            ->assertOk()
            ->assertJsonPath('data.reports.0.id', $report->id)
            ->assertJsonPath('data.reports.0.reportable_preview.type', 'post')
            ->assertJsonPath('data.reports.0.reporter.id', $reporter->id);
    }

    public function test_admin_can_update_report_status(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        $report = $this->reportFor($reporter, $post);
        $admin = $this->admin();

        Sanctum::actingAs($admin);

        $this->putJson("/api/admin/reports/{$report->id}/status", [
            'status' => Report::STATUS_REVIEWED,
            'action_taken' => 'Reviewed content.',
        ])
            ->assertOk()
            ->assertJsonPath('data.report.status', Report::STATUS_REVIEWED)
            ->assertJsonPath('data.report.reviewer.id', $admin->id);

        $this->assertDatabaseHas('reports', [
            'id' => $report->id,
            'status' => Report::STATUS_REVIEWED,
            'reviewed_by' => $admin->id,
            'action_taken' => 'Reviewed content.',
        ]);
    }

    public function test_admin_can_ban_a_user(): void
    {
        $target = User::factory()->create();
        Sanctum::actingAs($this->admin());

        $this->putJson("/api/admin/users/{$target->id}/ban", [
            'reason' => 'Violation of community guidelines.',
        ])
            ->assertOk()
            ->assertJsonPath('data.user.account_status', 'banned')
            ->assertJsonPath('data.user.ban_reason', 'Violation of community guidelines.');

        $this->assertDatabaseHas('users', [
            'id' => $target->id,
            'account_status' => 'banned',
            'ban_reason' => 'Violation of community guidelines.',
        ]);
    }

    public function test_admin_cannot_ban_themselves(): void
    {
        $admin = $this->admin();
        Sanctum::actingAs($admin);

        $this->putJson("/api/admin/users/{$admin->id}/ban", [
            'reason' => 'Nope.',
        ])->assertUnprocessable();
    }

    public function test_admin_can_unban_a_user(): void
    {
        $target = User::factory()->create([
            'account_status' => 'banned',
            'banned_at' => now(),
            'ban_reason' => 'Old reason',
        ]);

        Sanctum::actingAs($this->admin());

        $this->putJson("/api/admin/users/{$target->id}/unban")
            ->assertOk()
            ->assertJsonPath('data.user.account_status', 'active')
            ->assertJsonPath('data.user.ban_reason', null);
    }

    public function test_admin_can_delete_reported_post(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        $this->reportFor($reporter, $post);

        Sanctum::actingAs($this->admin());

        $this->deleteJson("/api/admin/posts/{$post->id}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('posts', ['id' => $post->id]);
    }

    public function test_report_responses_do_not_expose_sensitive_fields(): void
    {
        [$reporter, $post] = $this->reporterAndPost();
        $this->reportFor($reporter, $post);

        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/reports')
            ->assertOk()
            ->assertJsonMissingPath('data.reports.0.reporter.password')
            ->assertJsonMissingPath('data.reports.0.reporter.remember_token')
            ->assertJsonMissingPath('data.reports.0.reportable_preview.owner.password');
    }

    private function admin(): User
    {
        return User::factory()->create([
            'role' => 'admin',
            'account_status' => 'active',
        ]);
    }

    /**
     * @return array{0: User, 1: Post}
     */
    private function reporterAndPost(): array
    {
        $reporter = User::factory()->create();
        $owner = User::factory()->create();
        $post = Post::query()->create([
            'user_id' => $owner->id,
            'content' => 'Reported post',
        ]);

        return [$reporter, $post];
    }

    private function reportFor(User $reporter, Post $post): Report
    {
        return Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => Report::REASON_SPAM,
        ]);
    }
}
