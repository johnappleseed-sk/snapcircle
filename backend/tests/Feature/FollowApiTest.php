<?php

namespace Tests\Feature;

use App\Models\Follow;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FollowApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_follow_another_user(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$target->id}/follow")
            ->assertOk()
            ->assertJsonPath('message', 'User followed successfully')
            ->assertJsonPath('data.followers_count', 1)
            ->assertJsonPath('data.following_count', 1)
            ->assertJsonPath('data.is_followed_by_me', true)
            ->assertJsonPath('data.follow_status', 'following');

        $this->assertDatabaseHas('follows', [
            'follower_id' => $user->id,
            'following_id' => $target->id,
            'status' => Follow::STATUS_ACCEPTED,
        ]);
    }

    public function test_following_private_user_creates_pending_request(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create(['is_private' => true]);

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$target->id}/follow")
            ->assertOk()
            ->assertJsonPath('message', 'Follow request sent')
            ->assertJsonPath('data.follow_status', 'requested')
            ->assertJsonPath('data.is_followed_by_me', false)
            ->assertJsonPath('data.has_requested_follow', true);

        $this->assertDatabaseHas('follows', [
            'follower_id' => $user->id,
            'following_id' => $target->id,
            'status' => Follow::STATUS_PENDING,
        ]);
    }

    public function test_user_cannot_follow_themselves(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$user->id}/follow")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'You cannot follow yourself');
    }

    public function test_duplicate_follows_are_prevented(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();

        Follow::query()->create([
            'follower_id' => $user->id,
            'following_id' => $target->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/users/{$target->id}/follow")
            ->assertOk()
            ->assertJsonPath('message', 'User already followed')
            ->assertJsonPath('data.followers_count', 1)
            ->assertJsonPath('data.is_followed_by_me', true);

        $this->assertSame(1, Follow::query()
            ->where('follower_id', $user->id)
            ->where('following_id', $target->id)
            ->count());
    }

    public function test_user_can_unfollow_another_user(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();

        Follow::query()->create([
            'follower_id' => $user->id,
            'following_id' => $target->id,
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/users/{$target->id}/follow")
            ->assertOk()
            ->assertJsonPath('message', 'Follow removed successfully')
            ->assertJsonPath('data.followers_count', 0)
            ->assertJsonPath('data.following_count', 0)
            ->assertJsonPath('data.is_followed_by_me', false);
    }

    public function test_owner_can_approve_follow_request(): void
    {
        $requester = User::factory()->create();
        $owner = User::factory()->create(['is_private' => true]);
        Follow::query()->create([
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
            'status' => Follow::STATUS_PENDING,
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/follow-requests/{$requester->id}/approve")
            ->assertOk()
            ->assertJsonPath('message', 'Follow request approved.');

        $this->assertDatabaseHas('follows', [
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
            'status' => Follow::STATUS_ACCEPTED,
        ]);
    }

    public function test_owner_can_reject_follow_request(): void
    {
        $requester = User::factory()->create();
        $owner = User::factory()->create(['is_private' => true]);
        Follow::query()->create([
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
            'status' => Follow::STATUS_PENDING,
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/follow-requests/{$requester->id}/reject")
            ->assertOk()
            ->assertJsonPath('message', 'Follow request rejected.');

        $this->assertDatabaseMissing('follows', [
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
        ]);
    }

    public function test_user_can_cancel_pending_follow_request(): void
    {
        $requester = User::factory()->create();
        $owner = User::factory()->create(['is_private' => true]);
        Follow::query()->create([
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
            'status' => Follow::STATUS_PENDING,
        ]);

        Sanctum::actingAs($requester);

        $this->deleteJson("/api/users/{$owner->id}/follow")
            ->assertOk()
            ->assertJsonPath('data.follow_status', 'not_following');

        $this->assertDatabaseMissing('follows', [
            'follower_id' => $requester->id,
            'following_id' => $owner->id,
        ]);
    }

    public function test_followers_list_works(): void
    {
        $authUser = User::factory()->create();
        $target = User::factory()->create();

        Follow::query()->create([
            'follower_id' => $authUser->id,
            'following_id' => $target->id,
        ]);

        Sanctum::actingAs($authUser);

        $this->getJson("/api/users/{$target->id}/followers")
            ->assertOk()
            ->assertJsonPath('data.users.0.id', $authUser->id)
            ->assertJsonPath('data.meta.total', 1);
    }

    public function test_following_list_works(): void
    {
        $authUser = User::factory()->create();
        $target = User::factory()->create();

        Follow::query()->create([
            'follower_id' => $authUser->id,
            'following_id' => $target->id,
        ]);

        Sanctum::actingAs($authUser);

        $this->getJson("/api/users/{$authUser->id}/following")
            ->assertOk()
            ->assertJsonPath('data.users.0.id', $target->id)
            ->assertJsonPath('data.users.0.is_followed_by_me', true)
            ->assertJsonPath('data.meta.total', 1);
    }
}
