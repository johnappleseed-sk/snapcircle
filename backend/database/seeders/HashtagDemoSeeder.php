<?php

namespace Database\Seeders;

use App\Models\Post;
use Illuminate\Database\Seeder;

class HashtagDemoSeeder extends Seeder
{
    /**
     * Add realistic topic hashtags to existing demo posts without creating rows.
     */
    public function run(): void
    {
        $primaryTags = ['travel', 'citylife', 'foodie', 'streetstyle', 'weekend', 'nature', 'photography', 'friends'];
        $secondaryTags = ['snapcircle', 'dailyphoto', 'goodlight', 'localspots', 'creative', 'moments'];

        Post::query()
            ->orderBy('id')
            ->chunkById(500, function ($posts) use ($primaryTags, $secondaryTags): void {
                foreach ($posts as $index => $post) {
                    $content = trim((string) $post->content);
                    $content = preg_replace('/\s+#\d+\b/u', '', $content) ?? $content;

                    if (preg_match('/#[^\W\d_][\p{L}\p{N}_]{1,50}/u', $content)) {
                        continue;
                    }

                    $number = ((int) $post->id) + $index;
                    $post->forceFill([
                        'content' => trim($content
                            .' #'.$primaryTags[$number % count($primaryTags)]
                            .' #'.$secondaryTags[$number % count($secondaryTags)]),
                    ])->save();
                }
            });
    }
}
