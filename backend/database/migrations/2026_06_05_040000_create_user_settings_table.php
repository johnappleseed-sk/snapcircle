<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('account_status', 30)->default('active')->index()->after('last_active_at');
        });

        Schema::create('user_settings', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('allow_messages')->default(true);
            $table->boolean('show_email')->default(false);
            $table->boolean('push_notifications_enabled')->default(true);
            $table->boolean('email_notifications_enabled')->default(false);
            $table->boolean('marketing_emails_enabled')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_settings');

        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex(['account_status']);
            $table->dropColumn('account_status');
        });
    }
};
