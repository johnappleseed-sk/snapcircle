<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('username', 50)->nullable()->unique()->after('email');
            $table->string('cover_image')->nullable()->after('avatar');
            $table->string('location', 100)->nullable()->after('bio');
            $table->string('website')->nullable()->after('location');
            $table->date('date_of_birth')->nullable()->after('website');
            $table->boolean('is_private')->default(false)->index()->after('date_of_birth');
            $table->timestamp('last_active_at')->nullable()->index()->after('is_private');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropUnique(['username']);
            $table->dropIndex(['is_private']);
            $table->dropIndex(['last_active_at']);
            $table->dropColumn([
                'username',
                'cover_image',
                'location',
                'website',
                'date_of_birth',
                'is_private',
                'last_active_at',
            ]);
        });
    }
};
