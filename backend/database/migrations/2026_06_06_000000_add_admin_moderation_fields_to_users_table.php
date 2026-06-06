<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('role', 30)->default('user')->index()->after('account_status');
            $table->timestamp('banned_at')->nullable()->index()->after('role');
            $table->text('ban_reason')->nullable()->after('banned_at');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex(['role']);
            $table->dropIndex(['banned_at']);
            $table->dropColumn(['role', 'banned_at', 'ban_reason']);
        });
    }
};
