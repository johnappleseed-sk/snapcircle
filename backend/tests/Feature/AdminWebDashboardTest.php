<?php

namespace Tests\Feature;

use App\Models\Comment;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminWebDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dashboard_renders_operational_panels(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'account_status' => 'active',
        ]);
        $reporter = User::factory()->create();
        $author = User::factory()->create(['last_active_at' => now()]);
        $post = Post::query()->create([
            'user_id' => $author->id,
            'content' => 'Dashboard moderation post',
        ]);

        Comment::query()->create([
            'user_id' => $reporter->id,
            'post_id' => $post->id,
            'comment' => 'Needs a moderation glance',
        ]);
        Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => Report::REASON_SPAM,
            'description' => 'This looks spammy.',
        ]);
        Report::query()->create([
            'reporter_id' => $reporter->id,
            'reportable_type' => User::class,
            'reportable_id' => $author->id,
            'reason' => Report::REASON_FAKE_ACCOUNT,
            'status' => Report::STATUS_REVIEWED,
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
        ]);

        $this->actingAs($admin)
            ->get(route('admin.dashboard'))
            ->assertOk()
            ->assertSee('Moderation command center')
            ->assertSee('Seven-day activity')
            ->assertSee('Top report reasons')
            ->assertSee('Fresh posts')
            ->assertSee('Reported users')
            ->assertSee('Dashboard moderation post');
    }
}
