<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->index('created_at', 'users_created_at_index');
        });

        Schema::table('posts', function (Blueprint $table): void {
            $table->index('created_at', 'posts_created_at_index');
            $table->index('deleted_at', 'posts_deleted_at_index');
            $table->index(['user_id', 'created_at'], 'posts_user_id_created_at_index');
        });

        Schema::table('comments', function (Blueprint $table): void {
            $table->index('created_at', 'comments_created_at_index');
            $table->index('deleted_at', 'comments_deleted_at_index');
            $table->index(['post_id', 'created_at'], 'comments_post_id_created_at_index');
        });

        Schema::table('likes', function (Blueprint $table): void {
            $table->index(['post_id', 'created_at'], 'likes_post_id_created_at_index');
        });

        Schema::table('saved_posts', function (Blueprint $table): void {
            $table->index(['user_id', 'created_at'], 'saved_posts_user_id_created_at_index');
        });

        Schema::table('notifications', function (Blueprint $table): void {
            $table->index(['user_id', 'read_at'], 'notifications_user_id_read_at_index');
            $table->index(['user_id', 'created_at'], 'notifications_user_id_created_at_index');
        });

        Schema::table('stories', function (Blueprint $table): void {
            $table->index(['user_id', 'expires_at'], 'stories_user_id_expires_at_index');
        });

        Schema::table('conversations', function (Blueprint $table): void {
            $table->index('updated_at', 'conversations_updated_at_index');
        });

        Schema::table('messages', function (Blueprint $table): void {
            $table->index(['conversation_id', 'created_at'], 'messages_conversation_id_created_at_index');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table): void {
            $table->dropIndex('messages_conversation_id_created_at_index');
        });

        Schema::table('conversations', function (Blueprint $table): void {
            $table->dropIndex('conversations_updated_at_index');
        });

        Schema::table('stories', function (Blueprint $table): void {
            $table->dropIndex('stories_user_id_expires_at_index');
        });

        Schema::table('notifications', function (Blueprint $table): void {
            $table->dropIndex('notifications_user_id_read_at_index');
            $table->dropIndex('notifications_user_id_created_at_index');
        });

        Schema::table('saved_posts', function (Blueprint $table): void {
            $table->dropIndex('saved_posts_user_id_created_at_index');
        });

        Schema::table('likes', function (Blueprint $table): void {
            $table->dropIndex('likes_post_id_created_at_index');
        });

        Schema::table('comments', function (Blueprint $table): void {
            $table->dropIndex('comments_created_at_index');
            $table->dropIndex('comments_deleted_at_index');
            $table->dropIndex('comments_post_id_created_at_index');
        });

        Schema::table('posts', function (Blueprint $table): void {
            $table->dropIndex('posts_created_at_index');
            $table->dropIndex('posts_deleted_at_index');
            $table->dropIndex('posts_user_id_created_at_index');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex('users_created_at_index');
        });
    }
};
