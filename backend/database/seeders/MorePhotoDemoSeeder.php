<?php

namespace Database\Seeders;

use App\Models\Comment;
use App\Models\Like;
use App\Models\Post;
use App\Models\PostMedia;
use App\Models\SavedPost;
use App\Models\Story;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class MorePhotoDemoSeeder extends Seeder
{
    private const EXTRA_POSTS = 5000;

    /**
     * Add 5000 more realistic photo posts and refresh every profile/media URL.
     */
    public function run(): void
    {
        DB::disableQueryLog();

        $now = now();

        $this->refreshProfilePhotos($now);
        $this->refreshExistingMedia($now);

        $userIds = User::query()->pluck('id')->values()->all();
        if ($userIds === []) {
            return;
        }

        $start = (int) Post::withTrashed()->max('id') + 1;
        $this->createPosts($userIds, $start, $now);

        $posts = Post::query()
            ->whereBetween('id', [$start, $start + self::EXTRA_POSTS + 200])
            ->where('image_path', 'like', 'https://picsum.photos/seed/snapcircle-extra-post-%')
            ->orderBy('id')
            ->get(['id', 'created_at', 'updated_at'])
            ->values();

        $postIds = $posts->pluck('id')->all();

        $this->createPostMedia($posts);
        $this->createLikes($userIds, $postIds, $now);
        $this->createComments($userIds, $postIds, $now);
        $this->createSavedPosts($userIds, $postIds, $now);
    }

    private function refreshProfilePhotos(Carbon $now): void
    {
        User::query()
            ->orderBy('id')
            ->get(['id'])
            ->values()
            ->each(function (User $user, int $index) use ($now): void {
                $number = $index + 1;
                $user->forceFill([
                    'avatar' => "https://i.pravatar.cc/300?u=snapcircle-profile-$number",
                    'cover_image' => $this->photoUrl('profile-cover', $number, 1200, 480),
                    'updated_at' => $now,
                ])->save();
            });
    }

    private function refreshExistingMedia(Carbon $now): void
    {
        Post::withTrashed()
            ->orderBy('id')
            ->get(['id', 'image_path'])
            ->values()
            ->each(function (Post $post, int $index) use ($now): void {
                if (! $post->image_path) {
                    return;
                }

                $number = $index + 1;
                $post->forceFill([
                    'image_path' => $this->photoUrl('existing-post', $number, 1080, 1080),
                    'updated_at' => $now,
                ])->save();
            });

        PostMedia::query()
            ->orderBy('id')
            ->get(['id'])
            ->values()
            ->each(function (PostMedia $media, int $index) use ($now): void {
                $media->forceFill([
                    'path' => $this->photoUrl('existing-media', $index + 1, 1080, 1080),
                    'updated_at' => $now,
                ])->save();
            });

        Story::withTrashed()
            ->orderBy('id')
            ->get(['id'])
            ->values()
            ->each(function (Story $story, int $index) use ($now): void {
                $story->forceFill([
                    'media_path' => $this->photoUrl('existing-story', $index + 1, 720, 1280),
                    'updated_at' => $now,
                ])->save();
            });
    }

    private function createPosts(array $userIds, int $start, Carbon $now): void
    {
        $rows = [];
        $userCount = count($userIds);

        for ($offset = 0; $offset < self::EXTRA_POSTS; $offset++) {
            $number = $start + $offset;
            $createdAt = $now->copy()->subDays($offset % 120)->subMinutes($offset * 9)->toDateTimeString();

            $rows[] = [
                'user_id' => $userIds[($offset * 17) % $userCount],
                'content' => $this->caption($number),
                'image_path' => $this->photoUrl('extra-post', $number, 1080, 1080),
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ];

            if (count($rows) >= 500) {
                Post::query()->insert($rows);
                $rows = [];
            }
        }

        if ($rows !== []) {
            Post::query()->insert($rows);
        }
    }

    private function createPostMedia($posts): void
    {
        $rows = [];

        foreach ($posts as $index => $post) {
            $number = $post->id;
            $mediaCount = $index % 10 === 0 ? 4 : ($index % 5 === 0 ? 3 : ($index % 3 === 0 ? 2 : 1));

            for ($sort = 0; $sort < $mediaCount; $sort++) {
                $rows[] = [
                    'post_id' => $post->id,
                    'path' => $this->photoUrl('extra-media-'.($sort + 1), $number, 1080, 1080),
                    'type' => 'image',
                    'sort_order' => $sort,
                    'created_at' => $post->created_at,
                    'updated_at' => $post->updated_at,
                ];
            }

            if (count($rows) >= 1000) {
                PostMedia::query()->insert($rows);
                $rows = [];
            }
        }

        if ($rows !== []) {
            PostMedia::query()->insert($rows);
        }
    }

    private function createLikes(array $userIds, array $postIds, Carbon $now): void
    {
        $rows = [];
        $seen = [];
        $userCount = count($userIds);

        foreach ($postIds as $postIndex => $postId) {
            $likeCount = 2 + ($postIndex % 9);
            for ($i = 0; $i < $likeCount; $i++) {
                $userId = $userIds[($postIndex + ($i * 23)) % $userCount];
                $key = "$userId:$postId";
                if (isset($seen[$key])) {
                    continue;
                }
                $seen[$key] = true;
                $createdAt = $now->copy()->subMinutes($postIndex + $i)->toDateTimeString();
                $rows[] = [
                    'user_id' => $userId,
                    'post_id' => $postId,
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ];
            }

            if (count($rows) >= 1000) {
                Like::query()->insert($rows);
                $rows = [];
            }
        }

        if ($rows !== []) {
            Like::query()->insert($rows);
        }
    }

    private function createComments(array $userIds, array $postIds, Carbon $now): void
    {
        $comments = [
            'This photo feels alive.',
            'Great shot, love the mood here.',
            'That place looks beautiful.',
            'Saving this for inspiration.',
            'The lighting is perfect.',
            'This belongs on a postcard.',
        ];
        $rows = [];
        $userCount = count($userIds);

        foreach ($postIds as $postIndex => $postId) {
            $commentCount = $postIndex % 4;
            for ($i = 0; $i < $commentCount; $i++) {
                $createdAt = $now->copy()->subMinutes(($postIndex * 2) + $i)->toDateTimeString();
                $rows[] = [
                    'user_id' => $userIds[($postIndex + ($i * 29) + 7) % $userCount],
                    'post_id' => $postId,
                    'comment' => $comments[($postIndex + $i) % count($comments)],
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ];
            }

            if (count($rows) >= 1000) {
                Comment::query()->insert($rows);
                $rows = [];
            }
        }

        if ($rows !== []) {
            Comment::query()->insert($rows);
        }
    }

    private function createSavedPosts(array $userIds, array $postIds, Carbon $now): void
    {
        $rows = [];
        $seen = [];
        $userCount = count($userIds);

        foreach ($postIds as $postIndex => $postId) {
            if ($postIndex % 4 !== 0) {
                continue;
            }
            for ($i = 0; $i < 2; $i++) {
                $userId = $userIds[($postIndex + ($i * 31)) % $userCount];
                $key = "$userId:$postId";
                if (isset($seen[$key])) {
                    continue;
                }
                $seen[$key] = true;
                $createdAt = $now->copy()->subMinutes($postIndex + $i)->toDateTimeString();
                $rows[] = [
                    'user_id' => $userId,
                    'post_id' => $postId,
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ];
            }

            if (count($rows) >= 1000) {
                SavedPost::query()->insert($rows);
                $rows = [];
            }
        }

        if ($rows !== []) {
            SavedPost::query()->insert($rows);
        }
    }

    private function caption(int $number): string
    {
        $captions = [
            'Another real-photo moment for the SnapCircle feed.',
            'Fresh visual update from today.',
            'A little scene worth sharing.',
            'Real photo energy for the circle.',
            'Captured this while moving through the day.',
            'One more frame from the weekend.',
            'Small details, big mood.',
            'A clean shot for the timeline.',
        ];
        $primaryTags = [
            'travel',
            'citylife',
            'foodie',
            'streetstyle',
            'weekend',
            'nature',
            'photography',
            'friends',
        ];
        $secondaryTags = [
            'snapcircle',
            'dailyphoto',
            'goodlight',
            'localspots',
            'creative',
            'moments',
        ];

        return $captions[$number % count($captions)]
            .' #'.$primaryTags[$number % count($primaryTags)]
            .' #'.$secondaryTags[$number % count($secondaryTags)];
    }

    private function photoUrl(string $type, int $number, int $width, int $height): string
    {
        return "https://picsum.photos/seed/snapcircle-$type-$number/$width/$height";
    }
}
