<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\ReportResource;
use App\Models\Comment;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    public function reportPost(Request $request, Post $post): JsonResponse
    {
        return $this->store($request, $post);
    }

    public function reportComment(Request $request, Comment $comment): JsonResponse
    {
        return $this->store($request, $comment);
    }

    public function reportUser(Request $request, User $user): JsonResponse
    {
        return $this->store($request, $user);
    }

    public function storeGeneric(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'string', Rule::in(['post', 'comment', 'user', 'message'])],
            'id' => ['required', 'integer', 'min:1'],
        ]);

        $reportable = match ($validated['type']) {
            'post' => Post::query()->findOrFail($validated['id']),
            'comment' => Comment::query()->findOrFail($validated['id']),
            'user' => User::query()->findOrFail($validated['id']),
            'message' => Message::query()->findOrFail($validated['id']),
        };

        return $this->store($request, $reportable);
    }

    private function store(Request $request, Model $reportable): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', Rule::in(Report::reasons())],
            'description' => ['nullable', 'string', 'max:1000'],
            'details' => ['nullable', 'string', 'max:1000'],
        ]);

        $existingReport = Report::query()
            ->where('reporter_id', $request->user()->id)
            ->where('reportable_type', $reportable::class)
            ->where('reportable_id', $reportable->getKey())
            ->where('status', Report::STATUS_PENDING)
            ->first();

        if ($existingReport) {
            return ApiResponse::error('You already have a pending report for this item.', [], 422);
        }

        $report = Report::query()->create([
            'reporter_id' => $request->user()->id,
            'reportable_type' => $reportable::class,
            'reportable_id' => $reportable->getKey(),
            'reason' => $validated['reason'],
            'description' => $validated['description'] ?? $validated['details'] ?? null,
        ]);

        $report->load(['reporter.setting', 'reviewer.setting', 'reportable']);
        $this->loadReportableOwner($report);

        return ApiResponse::success('Report submitted successfully.', [
            'report' => ReportResource::make($report),
        ], 201);
    }

    private function loadReportableOwner(Report $report): void
    {
        $reportable = $report->reportable;

        if ($reportable instanceof Post || $reportable instanceof Comment) {
            $reportable->loadMissing('user.setting');
        }

        if ($reportable instanceof Message) {
            $reportable->loadMissing('sender.setting');
        }
    }
}
