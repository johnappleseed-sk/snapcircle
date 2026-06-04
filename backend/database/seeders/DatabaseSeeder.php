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
                'content' => 'Morning walk by the riverside. The light was perfect today.',
                'image_path' => 'posts/riverside-morning.jpg',
            ],
            [
                'user_id' => $users[1]->id,
                'content' => 'Trying a new noodle place near campus. Instant favorite.',
                'image_path' => 'posts/noodle-spot.jpg',
            ],
            [
                'user_id' => $users[2]->id,
                'content' => 'Sketching layout ideas for my social app assignment.',
                'image_path' => null,
            ],
            [
                'user_id' => $users[0]->id,
                'content' => 'Small photo dump from the weekend market.',
                'image_path' => 'posts/weekend-market.jpg',
            ],
            [
                'user_id' => $users[1]->id,
                'content' => 'Late-night coding session for the backend API.',
                'image_path' => null,
            ],
        ])->map(fn (array $post) => Post::query()->create($post));

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
