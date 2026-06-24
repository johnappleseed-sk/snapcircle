<?php

namespace Tests\Feature;

use App\Models\Comment;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminWebManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_management_pages_render_with_filters(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'account_status' => 'active',
        ]);
        $moderator = User::factory()->create([
            'role' => 'moderator',
            'account_status' => 'active',
            'last_active_at' => now(),
        ]);
        $reporter = User::factory()->create(['name' => 'Case Reporter']);
        $author = User::factory()->create([
            'name' => 'Filtered Author',
            'email' => 'filtered-author@example.test',
            'last_active_at' => now()->subDays(45),
        ]);
        $banned = User::factory()->create([
            'name' => 'Banned Member',
            'account_status' => 'banned',
            'banned_at' => now(),
            'ban_reason' => 'Repeated policy violations.',
        ]);
        $post = Post::query()->create([
            'user_id' => $author->id,
            'content' => 'Filtered dashboard post body',
        ]);
        $comment = Comment::query()->create([
            'user_id' => $reporter->id,
            'post_id' => $post->id,
            'comment' => 'Filtered comment body',
        ]);
        $report = Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => Report::REASON_SPAM,
            'description' => 'Filtered report description',
            'status' => Report::STATUS_REVIEWED,
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
            'action_taken' => 'Reviewed from management test.',
        ]);
        Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Comment::class,
            'reportable_id' => $comment->id,
            'reason' => Report::REASON_HARASSMENT,
        ]);
        Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => User::class,
            'reportable_id' => $banned->id,
            'reason' => Report::REASON_FAKE_ACCOUNT,
        ]);

        $this->actingAs($admin)
            ->get(route('admin.reports.index', ['search' => 'Filtered report', 'sort' => 'oldest']))
            ->assertOk()
            ->assertSee('Filtered report description')
            ->assertSee('Reviewed');

        $this->actingAs($admin)
            ->get(route('admin.posts.index', ['search' => 'dashboard post', 'author' => 'Filtered Author', 'sort' => 'engagement']))
            ->assertOk()
            ->assertSee('Filtered dashboard post body')
            ->assertSee('Filtered Author');

        $this->actingAs($admin)
            ->get(route('admin.comments.index', ['search' => 'Filtered comment', 'reports' => 'with', 'sort' => 'reports']))
            ->assertOk()
            ->assertSee('Filtered comment body')
            ->assertSee('Case Reporter');

        $this->actingAs($admin)
            ->get(route('admin.users.index', ['activity' => 'inactive_30d', 'sort' => 'reports_received']))
            ->assertOk()
            ->assertSee('Filtered Author');

        $this->actingAs($admin)
            ->get(route('admin.users.show', $banned))
            ->assertOk()
            ->assertSee('Reports received')
            ->assertSee('Repeated policy violations.');

        $this->actingAs($admin)
            ->get(route('admin.roles.index'))
            ->assertOk()
            ->assertSee('Permission matrix')
            ->assertSee($moderator->email);

        $this->actingAs($admin)
            ->get(route('admin.audit.index', ['event' => 'report_review']))
            ->assertOk()
            ->assertSee('Report reviewed')
            ->assertSee('Reviewed from management test.')
            ->assertSee('report #'.$report->id);
    }

    public function test_user_cannot_change_their_own_role(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'account_status' => 'active',
        ]);

        $this->actingAs($admin)
            ->put(route('admin.users.role', $admin), ['role' => 'user'])
            ->assertSessionHasErrors('role');

        $this->assertDatabaseHas('users', [
            'id' => $admin->id,
            'role' => 'admin',
        ]);
    }

    public function test_moderator_cannot_change_admin_accounts(): void
    {
        $moderator = User::factory()->create([
            'role' => 'moderator',
            'account_status' => 'active',
        ]);
        $admin = User::factory()->create([
            'role' => 'admin',
            'account_status' => 'active',
        ]);

        $this->actingAs($moderator)
            ->put(route('admin.users.role', $admin), ['role' => 'user'])
            ->assertSessionHasErrors('role');

        $this->assertDatabaseHas('users', [
            'id' => $admin->id,
            'role' => 'admin',
        ]);
    }
}
