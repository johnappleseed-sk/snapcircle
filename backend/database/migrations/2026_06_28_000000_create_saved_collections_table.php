<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('saved_collections', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 80);
            $table->timestamps();

            $table->unique(['user_id', 'name']);
            $table->index(['user_id', 'updated_at']);
        });

        Schema::create('saved_collection_posts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('saved_collection_id')->constrained()->cascadeOnDelete();
            $table->foreignId('post_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['saved_collection_id', 'post_id'], 'saved_collection_posts_unique');
            $table->index('post_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('saved_collection_posts');
        Schema::dropIfExists('saved_collections');
    }
};
