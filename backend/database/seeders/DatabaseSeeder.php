<?php

namespace Database\Seeders;

use App\Models\Comment;
use App\Models\Follow;
use App\Models\Like;
use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::query()->firstOrCreate(
            ['email' => 'admin@snapcircle.test'],
            [
                'name' => 'SnapCircle Admin',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'account_status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        $users = collect([
            [
                'name' => 'Maya Sok',
                'email' => 'maya@snapcircle.local',
                'password' => Hash::make('password'),
                'avatar' => 'avatars/maya.png',
                'bio' => 'Mobile photographer and coffee explorer.',
                'provider' => 'google',
                'provider_id' => 'google-demo-maya',
                'email_verified_at' => now(),
            ],
            [
                'name' => 'Dara Chen',
                'email' => 'dara@snapcircle.local',
                'password' => Hash::make('password'),
                'avatar' => 'avatars/dara.png',
                'bio' => 'Sharing weekend food spots and city walks.',
                'provider' => 'facebook',
                'provider_id' => 'facebook-demo-dara',
                'email_verified_at' => now(),
            ],
            [
                'name' => 'Lina Kim',
                'email' => 'lina@snapcircle.local',
                'password' => Hash::make('password'),
                'avatar' => null,
                'bio' => 'Design student posting notes, sketches, and campus life.',
                'provider' => null,
                'provider_id' => null,
                'email_verified_at' => now(),
            ],
        ])->map(fn (array $user) => User::query()->create($user));

        $posts = collect([
            [
                'user_id' => $users[0]->id,
                'content' => 'Morning walk by the riverside. The light was perfect today. #travel #goodlight',
                'image_path' => 'https://picsum.photos/seed/snapcircle-riverside-morning/1080/1080',
            ],
            [
                'user_id' => $users[1]->id,
                'content' => 'Trying a new noodle place near campus. Instant favorite. #foodie #localspots',
                'image_path' => 'https://picsum.photos/seed/snapcircle-noodle-spot/1080/1080',
            ],
            [
                'user_id' => $users[2]->id,
                'content' => 'Sketching layout ideas for my social app assignment. #creative #snapcircle',
                'image_path' => null,
            ],
            [
                'user_id' => $users[0]->id,
                'content' => 'Small photo dump from the weekend market. #weekend #citylife',
                'image_path' => 'https://picsum.photos/seed/snapcircle-weekend-market/1080/1080',
            ],
            [
                'user_id' => $users[1]->id,
                'content' => 'Late-night coding session for the backend API. #snapcircle #creative',
                'image_path' => null,
            ],
        ])->map(fn (array $post) => Post::query()->create($post));

        $posts->each(function (Post $post): void {
            if (! $post->image_path) {
                return;
            }

            $paths = str_starts_with($post->content, 'Small photo dump from the weekend market.')
                ? [
                    'https://picsum.photos/seed/snapcircle-weekend-market/1080/1080',
                    'https://picsum.photos/seed/snapcircle-weekend-market-2/1080/1080',
                    'https://picsum.photos/seed/snapcircle-weekend-market-3/1080/1080',
                ]
                : [$post->image_path];

            collect($paths)->each(fn (string $path, int $index) => $post->media()->create([
                'path' => $path,
                'type' => 'image',
                'sort_order' => $index,
            ]));
        });

        collect([
            ['user_id' => $users[1]->id, 'post_id' => $posts[0]->id, 'comment' => 'That photo looks peaceful.'],
            ['user_id' => $users[2]->id, 'post_id' => $posts[0]->id, 'comment' => 'The colors are so good.'],
            ['user_id' => $users[0]->id, 'post_id' => $posts[1]->id, 'comment' => 'Adding this place to my list.'],
            ['user_id' => $users[2]->id, 'post_id' => $posts[4]->id, 'comment' => 'Backend progress is the best kind of progress.'],
        ])->each(fn (array $comment) => Comment::query()->create($comment));

        collect([
            ['user_id' => $users[1]->id, 'post_id' => $posts[0]->id],
            ['user_id' => $users[2]->id, 'post_id' => $posts[0]->id],
            ['user_id' => $users[0]->id, 'post_id' => $posts[1]->id],
            ['user_id' => $users[0]->id, 'post_id' => $posts[2]->id],
            ['user_id' => $users[1]->id, 'post_id' => $posts[2]->id],
            ['user_id' => $users[2]->id, 'post_id' => $posts[3]->id],
        ])->each(fn (array $like) => Like::query()->create($like));

        collect([
            ['follower_id' => $users[0]->id, 'following_id' => $users[1]->id],
            ['follower_id' => $users[1]->id, 'following_id' => $users[0]->id],
            ['follower_id' => $users[2]->id, 'following_id' => $users[0]->id],
            ['follower_id' => $users[2]->id, 'following_id' => $users[1]->id],
        ])->each(fn (array $follow) => Follow::query()->create($follow));
    }
}
