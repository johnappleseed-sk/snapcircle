<?php

namespace Database\Seeders;

use App\Models\Comment;
use App\Models\Conversation;
use App\Models\Follow;
use App\Models\Like;
use App\Models\Message;
use App\Models\Post;
use App\Models\PostMedia;
use App\Models\SavedPost;
use App\Models\Story;
use App\Models\StoryView;
use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class LargeDemoSeeder extends Seeder
{
    private const USER_COUNT = 120;
    private const POST_COUNT = 1000;
    private const STORY_COUNT = 120;
    private const DEMO_DOMAIN = 'snapcircle.demo';

    /**
     * Seed a large, realistic demo dataset with remote real-photo URLs.
     */
    public function run(): void
    {
        DB::disableQueryLog();

        DB::transaction(function (): void {
            User::query()
                ->where('email', 'like', '%@'.self::DEMO_DOMAIN)
                ->get()
                ->each(fn (User $user) => $user->delete());

            $now = now();
            $users = $this->createUsers($now);
            $userIds = $users->pluck('id')->values()->all();

            $this->createFollows($userIds, $now);
            $posts = $this->createPosts($userIds, $now);
            $postIds = $posts->pluck('id')->values()->all();

            $this->createPostMedia($posts, $now);
            $this->createLikes($userIds, $postIds, $now);
            $this->createComments($userIds, $postIds, $now);
            $this->createSavedPosts($userIds, $postIds, $now);
            $this->createStories($userIds, $now);
            $this->createConversations($userIds, $now);
        });
    }

    private function createUsers(Carbon $now)
    {
        $firstNames = [
            'Maya', 'Dara', 'Lina', 'Soriya', 'Nika', 'Vannak', 'Sopheak', 'Rina',
            'Kiri', 'Thea', 'Arun', 'Sovan', 'Malis', 'Chan', 'Bopha', 'Rithy',
            'Kanya', 'Sela', 'Narin', 'Vicheka', 'Sokha', 'Reaksa', 'Samnang', 'Pich',
        ];
        $lastNames = [
            'Sok', 'Chen', 'Kim', 'Heng', 'Ly', 'Nguyen', 'Tran', 'Lim', 'Park',
            'Som', 'Keo', 'Long', 'Sun', 'Tan', 'Mao', 'Yin', 'Chhay', 'Phan',
        ];
        $locations = [
            'Phnom Penh', 'Siem Reap', 'Battambang', 'Kampot', 'Sihanoukville',
            'Bangkok', 'Ho Chi Minh City', 'Kuala Lumpur', 'Singapore', 'Da Nang',
        ];

        $users = collect();
        for ($i = 1; $i <= self::USER_COUNT; $i++) {
            $name = $firstNames[($i - 1) % count($firstNames)].' '.$lastNames[($i * 7) % count($lastNames)];
            $username = Str::slug($name, '.').'.'.$i;
            $createdAt = $now->copy()->subDays(180 - ($i % 150))->subMinutes($i * 11);

            $user = User::query()->create([
                'name' => $name,
                'email' => sprintf('demo%03d@%s', $i, self::DEMO_DOMAIN),
                'email_verified_at' => $createdAt,
                'username' => $username,
                'password' => Hash::make('password'),
                'avatar' => "https://i.pravatar.cc/300?u=snapcircle-demo-$i",
                'cover_image' => "https://picsum.photos/seed/snapcircle-cover-$i/1200/480",
                'bio' => $this->bioFor($i),
                'location' => $locations[$i % count($locations)],
                'website' => $i % 4 === 0 ? "https://example.com/$username" : null,
                'is_private' => $i % 11 === 0,
                'last_active_at' => $now->copy()->subMinutes($i * 3),
                'account_status' => 'active',
                'role' => $i <= 3 ? 'moderator' : 'user',
                'provider' => $i % 5 === 0 ? 'google' : null,
                'provider_id' => $i % 5 === 0 ? "google-demo-$i" : null,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]);

            UserSetting::query()->create([
                'user_id' => $user->id,
                'allow_messages' => $i % 13 !== 0,
                'show_email' => false,
                'push_notifications_enabled' => true,
                'email_notifications_enabled' => $i % 6 === 0,
                'marketing_emails_enabled' => $i % 10 === 0,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]);

            $users->push($user);
        }

        return $users;
    }

    private function createFollows(array $userIds, Carbon $now): void
    {
        $rows = [];
        $seen = [];
        $count = count($userIds);

        foreach ($userIds as $index => $followerId) {
            for ($offset = 1; $offset <= 9; $offset++) {
                $followingId = $userIds[($index + ($offset * 7)) % $count];
                if ($followingId === $followerId) {
                    continue;
                }

                $key = "$followerId:$followingId";
                if (isset($seen[$key])) {
                    continue;
                }

                $seen[$key] = true;
                $rows[] = [
                    'follower_id' => $followerId,
                    'following_id' => $followingId,
                    'status' => $offset === 9 && $index % 5 === 0
                        ? Follow::STATUS_PENDING
                        : Follow::STATUS_ACCEPTED,
                    'created_at' => $now->copy()->subDays(($index + $offset) % 90),
                    'updated_at' => $now->copy()->subDays(($index + $offset) % 90),
                ];
            }
        }

        collect($rows)->chunk(500)->each(fn ($chunk) => Follow::query()->insert($chunk->all()));
    }

    private function createPosts(array $userIds, Carbon $now)
    {
        $posts = collect();
        $count = count($userIds);

        for ($i = 1; $i <= self::POST_COUNT; $i++) {
            $createdAt = $now->copy()->subDays($i % 75)->subMinutes($i * 17);
            $photoUrl = $this->photoUrl('post', $i, 1080, 1080);

            $posts->push(Post::query()->create([
                'user_id' => $userIds[($i * 13) % $count],
                'content' => $this->postCaption($i),
                'image_path' => $photoUrl,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]));
        }

        return $posts;
    }

    private function createPostMedia($posts, Carbon $now): void
    {
        $rows = [];
        foreach ($posts as $index => $post) {
            $photoNumber = $index + 1;
            $mediaCount = $photoNumber % 9 === 0 ? 3 : ($photoNumber % 4 === 0 ? 2 : 1);

            for ($sort = 0; $sort < $mediaCount; $sort++) {
                $rows[] = [
                    'post_id' => $post->id,
                    'path' => $this->photoUrl('post-'.($sort + 1), $photoNumber, 1080, 1080),
                    'type' => 'image',
                    'sort_order' => $sort,
                    'created_at' => $post->created_at ?? $now,
                    'updated_at' => $post->created_at ?? $now,
                ];
            }
        }

        collect($rows)->chunk(500)->each(fn ($chunk) => PostMedia::query()->insert($chunk->all()));
    }

    private function createLikes(array $userIds, array $postIds, Carbon $now): void
    {
        $rows = [];
        $seen = [];
        $userCount = count($userIds);

        foreach ($postIds as $postIndex => $postId) {
            $likeCount = 3 + ($postIndex % 12);
            for ($i = 0; $i < $likeCount; $i++) {
                $userId = $userIds[($postIndex + ($i * 11)) % $userCount];
                $key = "$userId:$postId";
                if (isset($seen[$key])) {
                    continue;
                }
                $seen[$key] = true;
                $rows[] = [
                    'user_id' => $userId,
                    'post_id' => $postId,
                    'created_at' => $now->copy()->subMinutes($postIndex + $i),
                    'updated_at' => $now->copy()->subMinutes($postIndex + $i),
                ];
            }
        }

        collect($rows)->chunk(1000)->each(fn ($chunk) => Like::query()->insert($chunk->all()));
    }

    private function createComments(array $userIds, array $postIds, Carbon $now): void
    {
        $templates = [
            'This looks amazing.',
            'Adding this to my weekend list.',
            'The colors in this photo are so good.',
            'Such a clean shot.',
            'Love this moment.',
            'This place has great energy.',
            'Need to visit soon.',
            'Your feed is looking beautiful.',
        ];

        $rows = [];
        $userCount = count($userIds);
        foreach ($postIds as $postIndex => $postId) {
            $commentCount = $postIndex % 5;
            for ($i = 0; $i < $commentCount; $i++) {
                $rows[] = [
                    'user_id' => $userIds[($postIndex + ($i * 17) + 3) % $userCount],
                    'post_id' => $postId,
                    'comment' => $templates[($postIndex + $i) % count($templates)],
                    'created_at' => $now->copy()->subMinutes(($postIndex * 2) + $i),
                    'updated_at' => $now->copy()->subMinutes(($postIndex * 2) + $i),
                ];
            }
        }

        collect($rows)->chunk(1000)->each(fn ($chunk) => Comment::query()->insert($chunk->all()));
    }

    private function createSavedPosts(array $userIds, array $postIds, Carbon $now): void
    {
        $rows = [];
        $seen = [];
        $userCount = count($userIds);

        foreach ($postIds as $postIndex => $postId) {
            if ($postIndex % 3 !== 0) {
                continue;
            }
            for ($i = 0; $i < 3; $i++) {
                $userId = $userIds[($postIndex + ($i * 19)) % $userCount];
                $key = "$userId:$postId";
                if (isset($seen[$key])) {
                    continue;
                }
                $seen[$key] = true;
                $rows[] = [
                    'user_id' => $userId,
                    'post_id' => $postId,
                    'created_at' => $now->copy()->subMinutes($postIndex + $i),
                    'updated_at' => $now->copy()->subMinutes($postIndex + $i),
                ];
            }
        }

        collect($rows)->chunk(1000)->each(fn ($chunk) => SavedPost::query()->insert($chunk->all()));
    }

    private function createStories(array $userIds, Carbon $now): void
    {
        $stories = collect();
        foreach (array_slice($userIds, 0, self::STORY_COUNT) as $index => $userId) {
            $createdAt = $now->copy()->subHours($index % 20)->subMinutes($index * 3);
            $stories->push(Story::query()->create([
                'user_id' => $userId,
                'media_path' => $this->photoUrl('story', $index + 1, 720, 1280),
                'caption' => $this->storyCaption($index + 1),
                'expires_at' => $now->copy()->addHours(24 - ($index % 20)),
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]));
        }

        $rows = [];
        foreach ($stories as $storyIndex => $story) {
            for ($i = 0; $i < 8; $i++) {
                $viewerId = $userIds[($storyIndex + ($i * 13) + 5) % count($userIds)];
                if ($viewerId === $story->user_id) {
                    continue;
                }
                $rows[] = [
                    'story_id' => $story->id,
                    'user_id' => $viewerId,
                    'created_at' => $now->copy()->subMinutes($storyIndex + $i),
                    'updated_at' => $now->copy()->subMinutes($storyIndex + $i),
                ];
            }
        }

        collect($rows)->chunk(1000)->each(fn ($chunk) => StoryView::query()->insertOrIgnore($chunk->all()));
    }

    private function createConversations(array $userIds, Carbon $now): void
    {
        for ($i = 0; $i < 80; $i++) {
            $firstUserId = $userIds[$i % count($userIds)];
            $secondUserId = $userIds[($i * 7 + 11) % count($userIds)];
            if ($firstUserId === $secondUserId) {
                continue;
            }

            $conversation = Conversation::query()->create([
                'created_at' => $now->copy()->subDays($i % 20),
                'updated_at' => $now->copy()->subMinutes($i),
            ]);
            $conversation->users()->attach([$firstUserId, $secondUserId]);

            for ($message = 0; $message < 3; $message++) {
                Message::query()->create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $message % 2 === 0 ? $firstUserId : $secondUserId,
                    'message' => [
                        'Hey, did you see the new posts today?',
                        'Yes, the photo updates look great.',
                        'Let us catch up this weekend.',
                    ][$message],
                    'read_at' => $message < 2 ? $now->copy()->subMinutes($i) : null,
                    'created_at' => $now->copy()->subMinutes(($i * 3) + $message),
                    'updated_at' => $now->copy()->subMinutes(($i * 3) + $message),
                ]);
            }
        }
    }

    private function photoUrl(string $type, int $number, int $width, int $height): string
    {
        return "https://picsum.photos/seed/snapcircle-$type-$number/$width/$height";
    }

    private function bioFor(int $index): string
    {
        $bios = [
            'Street photos, cafe finds, and small city moments.',
            'Sharing food spots, weekend walks, and study life.',
            'Mobile photography and travel notes from around the city.',
            'Design student collecting inspiration in everyday places.',
            'Building my circle one photo at a time.',
        ];

        return $bios[$index % count($bios)];
    }

    private function postCaption(int $index): string
    {
        $captions = [
            'A quiet moment from today, saved for the circle.',
            'Found a little color in the middle of a busy day.',
            'Weekend light always makes the city feel new.',
            'Small update from my camera roll.',
            'Coffee, street noise, and a good walk.',
            'This view deserved a spot on the feed.',
            'A tiny scene that made me stop for a second.',
            'Photo dump energy, but make it SnapCircle.',
        ];
        $primaryTags = ['travel', 'citylife', 'foodie', 'streetstyle', 'weekend', 'nature', 'photography', 'friends'];
        $secondaryTags = ['snapcircle', 'dailyphoto', 'goodlight', 'localspots', 'creative', 'moments'];

        return $captions[$index % count($captions)]
            .' #'.$primaryTags[$index % count($primaryTags)]
            .' #'.$secondaryTags[$index % count($secondaryTags)];
    }

    private function storyCaption(int $index): string
    {
        $captions = [
            'Today in one frame.',
            'Quick story update.',
            'A small highlight.',
            'Fresh from the camera roll.',
            '24-hour mood.',
        ];

        return $captions[$index % count($captions)];
    }
}
