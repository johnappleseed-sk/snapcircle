<?php

namespace Tests\Feature;

use App\Models\Story;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StoryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_create_story(): void
    {
        Storage::fake('public');
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson('/api/stories', [
            'media' => UploadedFile::fake()->create('story.jpg', 128, 'image/jpeg'),
            'caption' => 'My story',
        ])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.story.caption', 'My story')
            ->assertJsonPath('data.story.is_owner', true);

        $story = Story::query()->firstOrFail();
        Storage::disk('public')->assertExists($story->media_path);
        $this->assertTrue($story->expires_at->greaterThan(now()->addHours(23)));
    }

    public function test_guest_cannot_create_story(): void
    {
        Storage::fake('public');

        $this->postJson('/api/stories', [
            'media' => UploadedFile::fake()->create('story.jpg', 128, 'image/jpeg'),
        ])->assertUnauthorized();
    }

    public function test_authenticated_user_can_list_active_stories(): void
    {
        $user = User::factory()->create();
        $story = $this->storyFor($user);

        Sanctum::actingAs($user);

        $this->getJson('/api/stories')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.data.0.id', $story->id);
    }

    public function test_expired_stories_are_not_returned(): void
    {
        $user = User::factory()->create();
        $this->storyFor($user, ['expires_at' => now()->subMinute()]);

        Sanctum::actingAs($user);

        $this->getJson('/api/stories')
            ->assertOk()
            ->assertJsonPath('data.total', 0);
    }

    public function test_authenticated_user_can_view_story(): void
    {
        [$owner, $viewer] = [User::factory()->create(), User::factory()->create()];
        $story = $this->storyFor($owner);

        Sanctum::actingAs($viewer);

        $this->postJson("/api/stories/{$story->id}/view")
            ->assertOk()
            ->assertJsonPath('data.viewed_by_me', true)
            ->assertJsonPath('data.views_count', 1);

        $this->assertDatabaseHas('story_views', [
            'story_id' => $story->id,
            'user_id' => $viewer->id,
        ]);
    }

    public function test_duplicate_story_views_are_prevented(): void
    {
        [$owner, $viewer] = [User::factory()->create(), User::factory()->create()];
        $story = $this->storyFor($owner);

        Sanctum::actingAs($viewer);

        $this->postJson("/api/stories/{$story->id}/view")->assertOk();
        $this->postJson("/api/stories/{$story->id}/view")
            ->assertOk()
            ->assertJsonPath('data.views_count', 1);

        $this->assertDatabaseCount('story_views', 1);
    }

    public function test_owner_can_delete_own_story(): void
    {
        Storage::fake('public');
        $owner = User::factory()->create();
        $story = $this->storyFor($owner, ['media_path' => 'stories/delete-me.jpg']);
        Storage::disk('public')->put($story->media_path, 'story');

        Sanctum::actingAs($owner);

        $this->deleteJson("/api/stories/{$story->id}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('stories', ['id' => $story->id]);
        Storage::disk('public')->assertMissing($story->media_path);
    }

    public function test_non_owner_cannot_delete_story(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $story = $this->storyFor($owner);

        Sanctum::actingAs($other);

        $this->deleteJson("/api/stories/{$story->id}")->assertForbidden();
    }

    public function test_user_stories_endpoint_works(): void
    {
        [$owner, $viewer] = [User::factory()->create(), User::factory()->create()];
        $story = $this->storyFor($owner);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/users/{$owner->id}/stories")
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $story->id);
    }

    public function test_story_response_includes_view_and_owner_flags(): void
    {
        $owner = User::factory()->create();
        $story = $this->storyFor($owner);

        Sanctum::actingAs($owner);

        $this->getJson("/api/stories/{$story->id}")
            ->assertOk()
            ->assertJsonPath('data.story.viewed_by_me', false)
            ->assertJsonPath('data.story.views_count', 0)
            ->assertJsonPath('data.story.is_owner', true)
            ->assertJsonPath('data.story.can_delete', true);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function storyFor(User $user, array $attributes = []): Story
    {
        return Story::query()->create(array_merge([
            'user_id' => $user->id,
            'media_path' => 'stories/demo.jpg',
            'caption' => 'Demo story',
            'expires_at' => now()->addDay(),
        ], $attributes));
    }
}
