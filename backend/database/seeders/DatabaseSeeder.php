<?php

namespace Database\Seeders;

use App\Models\Comment;
use App\Models\Conversation;
use App\Models\Follow;
use App\Models\Like;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Post;
use App\Models\SavedCollection;
use App\Models\SavedPost;
use App\Models\Story;
use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        Model::unguarded(function (): void {
            $this->clearDemoData();

            $users = $this->seedUsers();
            $this->seedFollows($users);
            $posts = $this->seedPosts($users);
            $comments = $this->seedComments($users, $posts);

            $this->seedLikes($users, $posts);
            $this->seedSavedPosts($users, $posts);
            $this->seedSavedCollections($users, $posts);
            $this->seedStories($users);
            $this->seedNotifications($users, $posts, $comments);
            $this->seedConversations($users);
        });
    }

    private function clearDemoData(): void
    {
        DB::statement('PRAGMA foreign_keys = OFF');

        collect([
            'story_replies',
            'story_reactions',
            'story_views',
            'stories',
            'messages',
            'conversation_user',
            'conversations',
            'notifications',
            'saved_collection_posts',
            'saved_collections',
            'saved_posts',
            'likes',
            'comments',
            'post_media',
            'reports',
            'posts',
            'follows',
            'user_blocks',
            'device_tokens',
            'personal_access_tokens',
            'user_settings',
            'users',
        ])->each(fn (string $table) => DB::table($table)->delete());

        DB::statement('PRAGMA foreign_keys = ON');
    }

    /**
     * @return array<string, User>
     */
    private function seedUsers(): array
    {
        $password = Hash::make('password');

        $profiles = [
            'admin' => [
                'name' => 'SnapCircle Admin',
                'email' => 'admin@snapcircle.test',
                'username' => 'snap_admin',
                'role' => 'admin',
                'bio' => 'Keeping SnapCircle tidy for demo day.',
                'location' => 'Phnom Penh, Cambodia',
                'website' => 'https://snapcircle.local/admin',
                'avatar' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=1200&q=80',
            ],
            'maya' => [
                'name' => 'Maya Sok',
                'email' => 'maya@snapcircle.local',
                'username' => 'mayasnap',
                'bio' => 'Mobile photographer chasing soft light, street food, and riverside mornings.',
                'location' => 'Phnom Penh, Cambodia',
                'website' => 'https://maya.photos',
                'avatar' => 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
                'provider' => 'google',
                'provider_id' => 'google-demo-maya',
            ],
            'dara' => [
                'name' => 'Dara Chen',
                'email' => 'dara@snapcircle.local',
                'username' => 'daralocal',
                'bio' => 'Food walks, coffee corners, and small-business finds around the city.',
                'location' => 'Siem Reap, Cambodia',
                'website' => 'https://daralocal.example',
                'avatar' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
                'provider' => 'facebook',
                'provider_id' => 'facebook-demo-dara',
            ],
            'lina' => [
                'name' => 'Lina Kim',
                'email' => 'lina@snapcircle.local',
                'username' => 'linamakes',
                'bio' => 'Design student documenting sketches, campus notes, and interface ideas.',
                'location' => 'Battambang, Cambodia',
                'website' => 'https://lina.design',
                'avatar' => 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
            ],
            'sopheak' => [
                'name' => 'Sopheak Vann',
                'email' => 'sopheak@snapcircle.local',
                'username' => 'sopheakmoves',
                'bio' => 'Cycling routes, weekend hikes, and practical fitness notes.',
                'location' => 'Kampot, Cambodia',
                'website' => 'https://sopheak.fit',
                'avatar' => 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1200&q=80',
            ],
            'nara' => [
                'name' => 'Nara Reyes',
                'email' => 'nara@snapcircle.local',
                'username' => 'narastudio',
                'bio' => 'Ceramics, product styling, and behind-the-scenes studio rituals.',
                'location' => 'Ho Chi Minh City, Vietnam',
                'website' => 'https://nara.studio',
                'avatar' => 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
                'cover_image' => 'https://images.unsplash.com/photo-1523413651479-597eb2da0ad6?auto=format&fit=crop&w=1200&q=80',
                'is_private' => true,
            ],
        ];

        $users = [];

        foreach ($profiles as $key => $profile) {
            $users[$key] = User::query()->create([
                ...$profile,
                'password' => $password,
                'account_status' => 'active',
                'email_verified_at' => now(),
                'last_active_at' => now()->subMinutes(match ($key) {
                    'maya' => 8,
                    'dara' => 17,
                    'lina' => 34,
                    'sopheak' => 52,
                    'nara' => 90,
                    default => 5,
                }),
            ]);

            UserSetting::query()->create([
                'user_id' => $users[$key]->id,
                'allow_messages' => $key !== 'nara',
                'show_email' => false,
                'push_notifications_enabled' => true,
            ]);
        }

        return $users;
    }

    /**
     * @param  array<string, User>  $users
     */
    private function seedFollows(array $users): void
    {
        collect([
            ['maya', 'dara'],
            ['maya', 'lina'],
            ['maya', 'sopheak'],
            ['dara', 'maya'],
            ['dara', 'lina'],
            ['dara', 'sopheak'],
            ['lina', 'maya'],
            ['lina', 'dara'],
            ['lina', 'nara'],
            ['sopheak', 'maya'],
            ['sopheak', 'dara'],
            ['nara', 'maya'],
        ])->each(fn (array $follow) => Follow::query()->create([
            'follower_id' => $users[$follow[0]]->id,
            'following_id' => $users[$follow[1]]->id,
            'status' => Follow::STATUS_ACCEPTED,
        ]));

        Follow::query()->create([
            'follower_id' => $users['sopheak']->id,
            'following_id' => $users['nara']->id,
            'status' => Follow::STATUS_PENDING,
        ]);
    }

    /**
     * @param  array<string, User>  $users
     * @return array<string, Post>
     */
    private function seedPosts(array $users): array
    {
        $postData = [
            'riverside' => [
                'user' => 'maya',
                'content' => 'Morning walk by the riverside. The city was quiet for exactly twelve minutes. #travel #goodlight #phnompenh',
                'images' => [
                    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1470770903676-69b98201ea1c?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'noodles' => [
                'user' => 'dara',
                'content' => 'Found a tiny noodle shop near the old market. Broth: rich. Chili oil: not joking around. #foodie #localspots',
                'images' => [
                    'https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'design' => [
                'user' => 'lina',
                'content' => 'Sketching layout ideas for my social app assignment. The empty states are finally less empty. #creative #uiux #snapcircle',
                'images' => [
                    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'ride' => [
                'user' => 'sopheak',
                'content' => 'Sunrise ride out of Kampot. Flat road, warm air, mango smoothie at kilometer 28. #cycling #weekend',
                'images' => [
                    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'ceramics' => [
                'user' => 'nara',
                'content' => 'Fresh glaze tests from the studio. The blue one surprised everyone. #ceramics #handmade',
                'images' => [
                    'https://images.unsplash.com/photo-1493106819501-66d381c466f1?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1523413651479-597eb2da0ad6?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'coffee' => [
                'user' => 'dara',
                'content' => 'A quiet corner table, one iced latte, and a backlog of saved places to review. #coffee #citylife',
                'images' => [
                    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'market' => [
                'user' => 'maya',
                'content' => 'Weekend market photo dump: flowers, fabric, and the best tiny pancakes. #weekend #streetphotography',
                'images' => [
                    'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1516594798947-e65505dbb29d?auto=format&fit=crop&w=1080&q=80',
                    'https://images.unsplash.com/photo-1498579397066-22750a3cb424?auto=format&fit=crop&w=1080&q=80',
                ],
            ],
            'campus' => [
                'user' => 'lina',
                'content' => 'Campus critique day. Everyone had a different favorite screen, which is either good news or a plot twist. #designschool',
                'images' => [],
            ],
        ];

        $posts = [];

        foreach ($postData as $key => $data) {
            $images = $data['images'];
            $post = Post::query()->create([
                'user_id' => $users[$data['user']]->id,
                'content' => $data['content'],
                'image_path' => $images[0] ?? null,
                'created_at' => now()->subHours(count($posts) * 5 + 2),
                'updated_at' => now()->subHours(count($posts) * 5 + 2),
            ]);

            foreach ($images as $index => $path) {
                $post->media()->create([
                    'path' => $path,
                    'type' => 'image',
                    'sort_order' => $index,
                ]);
            }

            $posts[$key] = $post;
        }

        return $posts;
    }

    /**
     * @param  array<string, User>  $users
     * @param  array<string, Post>  $posts
     * @return array<string, Comment>
     */
    private function seedComments(array $users, array $posts): array
    {
        $commentData = [
            'dara_on_riverside' => ['dara', 'riverside', 'That first frame feels like a postcard.'],
            'lina_on_riverside' => ['lina', 'riverside', 'The colors are so soft. Saving this for moodboard energy.'],
            'maya_on_noodles' => ['maya', 'noodles', 'Drop the location, please. This looks dangerous in the best way.'],
            'sopheak_on_noodles' => ['sopheak', 'noodles', 'Post-ride lunch candidate confirmed.'],
            'nara_on_design' => ['nara', 'design', 'The spacing on that second sketch already feels calm.'],
            'maya_on_design' => ['maya', 'design', 'Empty states deserve personality. This is cute.'],
            'dara_on_ride' => ['dara', 'ride', 'Mango smoothie at km 28 is the real route marker.'],
            'lina_on_ceramics' => ['lina', 'ceramics', 'Blue glaze wins. No contest.'],
            'sopheak_on_market' => ['sopheak', 'market', 'The flower shot is my favorite.'],
        ];

        $comments = [];

        foreach ($commentData as $key => [$userKey, $postKey, $body]) {
            $comments[$key] = Comment::query()->create([
                'user_id' => $users[$userKey]->id,
                'post_id' => $posts[$postKey]->id,
                'comment' => $body,
            ]);
        }

        return $comments;
    }

    /**
     * @param  array<string, User>  $users
     * @param  array<string, Post>  $posts
     */
    private function seedLikes(array $users, array $posts): void
    {
        collect([
            ['dara', 'riverside'], ['lina', 'riverside'], ['sopheak', 'riverside'], ['nara', 'riverside'],
            ['maya', 'noodles'], ['lina', 'noodles'], ['sopheak', 'noodles'],
            ['maya', 'design'], ['dara', 'design'], ['nara', 'design'],
            ['maya', 'ride'], ['dara', 'ride'], ['lina', 'ride'],
            ['maya', 'ceramics'], ['dara', 'ceramics'], ['lina', 'ceramics'],
            ['dara', 'market'], ['lina', 'market'], ['sopheak', 'market'], ['nara', 'market'],
            ['maya', 'coffee'], ['lina', 'coffee'],
        ])->each(fn (array $like) => Like::query()->create([
            'user_id' => $users[$like[0]]->id,
            'post_id' => $posts[$like[1]]->id,
        ]));
    }

    /**
     * @param  array<string, User>  $users
     * @param  array<string, Post>  $posts
     */
    private function seedSavedPosts(array $users, array $posts): void
    {
        collect([
            ['maya', 'noodles'], ['maya', 'ceramics'],
            ['dara', 'riverside'], ['dara', 'ride'],
            ['lina', 'market'], ['lina', 'coffee'],
            ['sopheak', 'noodles'],
        ])->each(fn (array $saved) => SavedPost::query()->create([
            'user_id' => $users[$saved[0]]->id,
            'post_id' => $posts[$saved[1]]->id,
        ]));
    }

    /**
     * @param  array<string, User>  $users
     * @param  array<string, Post>  $posts
     */
    private function seedSavedCollections(array $users, array $posts): void
    {
        $collections = [
            ['maya', 'Food to try', ['noodles', 'coffee']],
            ['maya', 'Creative inspiration', ['ceramics', 'design']],
            ['dara', 'Photo walk ideas', ['riverside', 'market']],
            ['lina', 'Moodboard', ['market', 'coffee', 'ceramics']],
        ];

        foreach ($collections as [$userKey, $name, $postKeys]) {
            $collection = SavedCollection::query()->create([
                'user_id' => $users[$userKey]->id,
                'name' => $name,
            ]);

            foreach ($postKeys as $postKey) {
                SavedPost::query()->firstOrCreate([
                    'user_id' => $users[$userKey]->id,
                    'post_id' => $posts[$postKey]->id,
                ]);
                $collection->posts()->syncWithoutDetaching([$posts[$postKey]->id]);
            }
        }
    }

    /**
     * @param  array<string, User>  $users
     */
    private function seedStories(array $users): void
    {
        collect([
            ['maya', 'Golden hour from the bridge.', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80'],
            ['dara', 'Today’s test kitchen table.', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=80'],
            ['lina', 'Critique wall before everyone arrives.', 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80'],
            ['sopheak', 'Route check before sunrise.', 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=900&q=80'],
        ])->each(fn (array $story, int $index) => Story::query()->create([
            'user_id' => $users[$story[0]]->id,
            'caption' => $story[1],
            'media_path' => $story[2],
            'expires_at' => now()->addHours(22 - $index),
            'created_at' => now()->subHours($index + 1),
            'updated_at' => now()->subHours($index + 1),
        ]));
    }

    /**
     * @param  array<string, User>  $users
     * @param  array<string, Post>  $posts
     * @param  array<string, Comment>  $comments
     */
    private function seedNotifications(array $users, array $posts, array $comments): void
    {
        collect([
            ['maya', 'dara', Notification::TYPE_POST_COMMENTED, 'riverside', 'dara_on_riverside', 'Dara commented on your riverside post.'],
            ['maya', 'lina', Notification::TYPE_POST_LIKED, 'market', null, 'Lina liked your market photo dump.'],
            ['dara', 'maya', Notification::TYPE_POST_COMMENTED, 'noodles', 'maya_on_noodles', 'Maya asked for the noodle shop location.'],
            ['lina', 'nara', Notification::TYPE_POST_COMMENTED, 'design', 'nara_on_design', 'Nara commented on your design sketch.'],
            ['sopheak', 'maya', Notification::TYPE_POST_LIKED, 'ride', null, 'Maya liked your sunrise ride.'],
            ['nara', 'sopheak', Notification::TYPE_FOLLOW_REQUESTED, null, null, 'Sopheak requested to follow your private studio updates.'],
        ])->each(fn (array $notification, int $index) => Notification::query()->create([
            'user_id' => $users[$notification[0]]->id,
            'actor_id' => $users[$notification[1]]->id,
            'type' => $notification[2],
            'post_id' => $notification[3] ? $posts[$notification[3]]->id : null,
            'comment_id' => $notification[4] ? $comments[$notification[4]]->id : null,
            'data' => ['message' => $notification[5]],
            'read_at' => $index > 2 ? now()->subHours($index) : null,
            'created_at' => now()->subMinutes(($index + 1) * 18),
            'updated_at' => now()->subMinutes(($index + 1) * 18),
        ]));
    }

    /**
     * @param  array<string, User>  $users
     */
    private function seedConversations(array $users): void
    {
        $threads = [
            ['maya', 'dara', [
                ['maya', 'That noodle place from your post looks incredible.'],
                ['dara', 'It is. I’ll send the pin before lunch.'],
                ['maya', 'Perfect, adding it to tomorrow’s photo walk.'],
            ]],
            ['lina', 'nara', [
                ['nara', 'Your wireframes are getting really polished.'],
                ['lina', 'Thank you. I’m trying to make the profile flow feel lighter.'],
                ['nara', 'Show me after critique. I have opinions about cards.'],
            ]],
            ['sopheak', 'dara', [
                ['sopheak', 'Is that cafe bicycle-friendly?'],
                ['dara', 'Yes, there is a rack right by the side entrance.'],
            ]],
        ];

        foreach ($threads as [$first, $second, $messages]) {
            $conversation = Conversation::query()->create();
            $conversation->users()->attach([$users[$first]->id, $users[$second]->id]);

            foreach ($messages as $index => [$sender, $body]) {
                Message::query()->create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $users[$sender]->id,
                    'message' => $body,
                    'read_at' => $index < count($messages) - 1 ? now()->subMinutes(10) : null,
                    'created_at' => now()->subMinutes((count($messages) - $index) * 7),
                    'updated_at' => now()->subMinutes((count($messages) - $index) * 7),
                ]);
            }
        }
    }
}
