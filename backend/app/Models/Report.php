<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Report extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_REVIEWED = 'reviewed';
    public const STATUS_DISMISSED = 'dismissed';
    public const STATUS_ACTION_TAKEN = 'action_taken';

    public const REASON_SPAM = 'spam';
    public const REASON_HARASSMENT = 'harassment';
    public const REASON_INAPPROPRIATE = 'inappropriate_content';
    public const REASON_FAKE_ACCOUNT = 'fake_account';
    public const REASON_VIOLENCE = 'violence';
    public const REASON_OTHER = 'other';

    protected $fillable = [
        'reporter_id',
        'reportable_type',
        'reportable_id',
        'reason',
        'description',
        'status',
        'reviewed_by',
        'reviewed_at',
        'action_taken',
    ];

    protected $attributes = [
        'status' => self::STATUS_PENDING,
    ];

    protected function casts(): array
    {
        return [
            'reviewed_at' => 'datetime',
        ];
    }

    public static function reasons(): array
    {
        return [
            self::REASON_SPAM,
            self::REASON_HARASSMENT,
            self::REASON_INAPPROPRIATE,
            self::REASON_FAKE_ACCOUNT,
            self::REASON_VIOLENCE,
            self::REASON_OTHER,
        ];
    }

    public static function statuses(): array
    {
        return [
            self::STATUS_PENDING,
            self::STATUS_REVIEWED,
            self::STATUS_DISMISSED,
            self::STATUS_ACTION_TAKEN,
        ];
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function reportable(): MorphTo
    {
        return $this->morphTo();
    }
}
