<?php

namespace Tests\Feature;

use App\Models\Follow;
use App\Models\Like;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ExploreApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_fetch_explore_posts(): void
    {
        [$user, $author] = [User::factory()->create(), User::factory()->create()];
        $post = $this->postFor($author, 'Explore me');

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/posts')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.data.0.id', $post->id)
            ->assertJsonPath('data.data.0.user.id', $author->id);
    }

    public function test_authenticated_user_can_fetch_explore_users(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/users')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.data.0.id', $other->id);
    }

    public function test_search_filters_posts(): void
    {
        [$user, $author] = [User::factory()->create(), User::factory()->create()];
        $match = $this->postFor($author, 'Sunset discovery');
        $this->postFor($author, 'Coffee notes');

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/posts?search=sunset')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $match->id)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_search_filters_users(): void
    {
        $user = User::factory()->create();
        $match = User::factory()->create(['name' => 'Discovery Friend']);
        User::factory()->create(['name' => 'Another Person']);

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/users?search=Discovery')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $match->id)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_trending_posts_endpoint_works(): void
    {
        [$user, $author] = [User::factory()->create(), User::factory()->create()];
        $quiet = $this->postFor($author, 'Quiet post');
        $popular = $this->postFor($author, 'Popular post');
        Like::query()->create(['user_id' => $user->id, 'post_id' => $popular->id]);

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/trending-posts')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $popular->id)
            ->assertJsonPath('data.data.1.id', $quiet->id);
    }

    public function test_recommended_users_excludes_already_followed_users(): void
    {
        [$user, $followed, $recommended] = [
            User::factory()->create(),
            User::factory()->create(),
            User::factory()->create(),
        ];
        Follow::query()->create([
            'follower_id' => $user->id,
            'following_id' => $followed->id,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/recommended-users')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $recommended->id)
            ->assertJsonMissing(['id' => $followed->id]);
    }

    public function test_recommended_users_excludes_authenticated_user(): void
    {
        $user = User::factory()->create();
        $recommended = User::factory()->create();

        Sanctum::actingAs($user);

        $this->getJson('/api/explore/recommended-users')
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $recommended->id)
            ->assertJsonMissing(['id' => $user->id]);
    }

    public function test_guests_cannot_access_explore_endpoints(): void
    {
        $this->getJson('/api/explore/posts')->assertUnauthorized();
        $this->getJson('/api/explore/users')->assertUnauthorized();
        $this->getJson('/api/explore/trending-posts')->assertUnauthorized();
        $this->getJson('/api/explore/recommended-users')->assertUnauthorized();
        $this->getJson('/api/explore/search?q=test')->assertUnauthorized();
    }

    public function test_responses_do_not_expose_sensitive_user_fields(): void
    {
        [$user, $other] = [
            User::factory()->create(),
            User::factory()->create(['provider_id' => 'secret-provider-id']),
        ];

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/explore/users')->assertOk();

        $response->assertJsonMissingPath('data.data.0.provider_id')
            ->assertJsonMissingPath('data.data.0.password')
            ->assertJsonMissingPath('data.data.0.remember_token');
    }

    private function postFor(User $user, string $content): Post
    {
        return Post::query()->create([
            'user_id' => $user->id,
            'content' => $content,
        ]);
    }
}
