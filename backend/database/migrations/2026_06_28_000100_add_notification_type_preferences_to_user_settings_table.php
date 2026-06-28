<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_settings', function (Blueprint $table): void {
            $table->boolean('notify_likes')->default(true)->after('push_notifications_enabled');
            $table->boolean('notify_comments')->default(true)->after('notify_likes');
            $table->boolean('notify_follows')->default(true)->after('notify_comments');
            $table->boolean('notify_follow_requests')->default(true)->after('notify_follows');
            $table->boolean('notify_messages')->default(true)->after('notify_follow_requests');
            $table->boolean('notify_mentions')->default(true)->after('notify_messages');
        });
    }

    public function down(): void
    {
        Schema::table('user_settings', function (Blueprint $table): void {
            $table->dropColumn([
                'notify_likes',
                'notify_comments',
                'notify_follows',
                'notify_follow_requests',
                'notify_messages',
                'notify_mentions',
            ]);
        });
    }
};
