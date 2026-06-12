<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('post_media', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('post_id')->constrained()->cascadeOnDelete();
            $table->string('path');
            $table->string('type')->default('image');
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();

            $table->index(['post_id', 'sort_order']);
        });

        $now = now();
        DB::table('posts')
            ->whereNotNull('image_path')
            ->orderBy('id')
            ->select(['id', 'image_path'])
            ->chunkById(100, function ($posts) use ($now): void {
                $rows = $posts->map(fn ($post): array => [
                    'post_id' => $post->id,
                    'path' => $post->image_path,
                    'type' => 'image',
                    'sort_order' => 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])->all();

                DB::table('post_media')->insert($rows);
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('post_media');
    }
};
