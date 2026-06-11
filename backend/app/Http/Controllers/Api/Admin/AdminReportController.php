<?php

namespace App\Http\Controllers\Api\Admin;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\ReportResource;
use App\Models\Comment;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', 'string', Rule::in(Report::statuses())],
            'type' => ['sometimes', 'string', Rule::in(['post', 'comment', 'user', 'message'])],
            'reason' => ['sometimes', 'string', Rule::in(Report::reasons())],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $reports = Report::query()
            ->with(['reporter.setting', 'reviewer.setting', 'reportable'])
            ->when(isset($validated['status']), fn ($query) => $query->where('status', $validated['status']))
            ->when(isset($validated['reason']), fn ($query) => $query->where('reason', $validated['reason']))
            ->when(isset($validated['type']), function ($query) use ($validated): void {
                $query->where('reportable_type', $this->classForType($validated['type']));
            })
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        $this->loadReportableOwners($reports->items());

        return ApiResponse::paginated(
            'Reports fetched successfully',
            'reports',
            $reports,
            ReportResource::collection($reports->items())
        );
    }

    public function show(Report $report): JsonResponse
    {
        $report->load(['reporter.setting', 'reviewer.setting', 'reportable']);
        $this->loadReportableOwners([$report]);

        return ApiResponse::success('Report fetched successfully', [
            'report' => ReportResource::make($report),
        ]);
    }

    public function updateStatus(Request $request, Report $report): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['required', 'string', Rule::in(Report::statuses())],
            'action_taken' => ['nullable', 'string', 'max:255'],
        ]);

        $report->update([
            'status' => $validated['status'],
            'action_taken' => $validated['action_taken'] ?? null,
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
        ]);

        $report->load(['reporter.setting', 'reviewer.setting', 'reportable']);
        $this->loadReportableOwners([$report]);

        return ApiResponse::success('Report status updated successfully', [
            'report' => ReportResource::make($report),
        ]);
    }

    private function classForType(string $type): string
    {
        return match ($type) {
            'post' => Post::class,
            'comment' => Comment::class,
            'user' => User::class,
            'message' => Message::class,
        };
    }

    /**
     * @param  array<int, Report>  $reports
     */
    private function loadReportableOwners(array $reports): void
    {
        foreach ($reports as $report) {
            $reportable = $report->reportable;

            if ($reportable instanceof Post || $reportable instanceof Comment) {
                $reportable->loadMissing('user.setting');
            }

            if ($reportable instanceof Message) {
                $reportable->loadMissing('sender.setting');
            }
        }
    }
}
