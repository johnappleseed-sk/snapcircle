<?php

namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\Story;
use App\Models\User;
use App\Support\Pagination;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class AdminWebController extends Controller
{
    public function login(): View|RedirectResponse
    {
        if (Auth::check() && $this->canAccessAdmin(Auth::user())) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.auth.login');
    }

    public function authenticate(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('email', $credentials['email'])->first();

        if (! $user || ! $user->password || ! Hash::check($credentials['password'], $user->password)) {
            return back()
                ->withErrors(['email' => 'These credentials do not match our records.'])
                ->onlyInput('email');
        }

        if (! $this->canAccessAdmin($user)) {
            return back()
                ->withErrors(['email' => 'This account does not have admin access.'])
                ->onlyInput('email');
        }

        Auth::login($user, $request->boolean('remember'));
        $request->session()->regenerate();

        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    public function dashboard(): View
    {
        $statusCounts = Report::query()
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');
        $reasonCounts = Report::query()
            ->selectRaw('reason, count(*) as total')
            ->groupBy('reason')
            ->orderByDesc('total')
            ->limit(5)
            ->pluck('total', 'reason');
        $totalReports = (int) $statusCounts->sum();
        $resolvedReports = (int) $statusCounts
            ->only([Report::STATUS_REVIEWED, Report::STATUS_DISMISSED, Report::STATUS_ACTION_TAKEN])
            ->sum();
        $oldestPendingReport = Report::query()
            ->where('status', Report::STATUS_PENDING)
            ->oldest()
            ->first();

        return view('admin.dashboard', [
            'stats' => [
                'total_users' => User::query()->count(),
                'active_users' => User::query()->where('account_status', 'active')->count(),
                'banned_users' => User::query()->where('account_status', 'banned')->count(),
                'total_posts' => Post::query()->count(),
                'total_comments' => Comment::query()->count(),
                'total_reports' => Report::query()->count(),
                'pending_reports' => Report::query()->where('status', Report::STATUS_PENDING)->count(),
                'total_stories' => Story::query()->count(),
                'total_messages' => Message::query()->count(),
                'new_users_today' => User::query()->whereDate('created_at', today())->count(),
                'new_posts_today' => Post::query()->whereDate('created_at', today())->count(),
                'reports_today' => Report::query()->whereDate('created_at', today())->count(),
                'active_last_24h' => User::query()->where('last_active_at', '>=', now()->subDay())->count(),
                'reviewed_today' => Report::query()->whereDate('reviewed_at', today())->count(),
                'pending_older_than_day' => Report::query()
                    ->where('status', Report::STATUS_PENDING)
                    ->where('created_at', '<=', now()->subDay())
                    ->count(),
                'resolution_rate' => $totalReports > 0 ? round(($resolvedReports / $totalReports) * 100) : 0,
            ],
            'statusCounts' => collect(Report::statuses())
                ->mapWithKeys(fn (string $status): array => [$status => (int) ($statusCounts[$status] ?? 0)]),
            'reasonCounts' => $reasonCounts,
            'activitySeries' => collect(range(6, 0))->map(function (int $daysAgo): array {
                $date = now()->subDays($daysAgo);

                return [
                    'label' => $date->format('M j'),
                    'users' => User::query()->whereDate('created_at', $date)->count(),
                    'posts' => Post::query()->whereDate('created_at', $date)->count(),
                    'reports' => Report::query()->whereDate('created_at', $date)->count(),
                ];
            }),
            'recentReports' => $this->reportsQuery(request())
                ->limit(5)
                ->get(),
            'oldestPendingReport' => $oldestPendingReport,
            'recentUsers' => User::query()
                ->withCount(['posts', 'followers'])
                ->latest()
                ->limit(5)
                ->get(),
            'recentPosts' => Post::query()
                ->with('user')
                ->withCount(['likes', 'comments', 'reports'])
                ->latest()
                ->limit(5)
                ->get(),
            'recentComments' => Comment::query()
                ->with(['user', 'post.user'])
                ->withCount('reports')
                ->latest()
                ->limit(5)
                ->get(),
            'flaggedUsers' => User::query()
                ->withCount('receivedReports')
                ->whereHas('receivedReports')
                ->orderByDesc('received_reports_count')
                ->limit(5)
                ->get(),
        ]);
    }

    public function reports(Request $request): View
    {
        $reports = $this->reportsQuery($request)
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.reports.index', [
            'reports' => $reports,
            'statuses' => Report::statuses(),
            'reasons' => Report::reasons(),
        ]);
    }

    public function report(Report $report): View
    {
        $report->load(['reporter', 'reviewer', 'reportable']);
        $this->loadReportableOwner($report);

        return view('admin.reports.show', [
            'report' => $report,
            'statuses' => Report::statuses(),
        ]);
    }

    public function updateReport(Request $request, Report $report): RedirectResponse
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

        return back()->with('status', 'Report status updated.');
    }

    public function users(Request $request): View
    {
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'role' => ['sometimes', 'nullable', Rule::in(['user', 'admin', 'moderator'])],
            'account_status' => ['sometimes', 'nullable', Rule::in(['active', 'deactivated', 'banned'])],
        ]);

        $users = User::query()
            ->withCount(['posts', 'followers', 'following', 'reports'])
            ->when($validated['role'] ?? null, fn ($query, $role) => $query->where('role', $role))
            ->when($validated['account_status'] ?? null, fn ($query, $status) => $query->where('account_status', $status))
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('username', 'like', "%{$search}%");
                });
            })
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.users.index', ['users' => $users]);
    }

    public function user(User $user): View
    {
        $user->loadCount(['posts', 'followers', 'following', 'reports', 'receivedReports']);

        return view('admin.users.show', ['user' => $user]);
    }

    public function updateUserRole(Request $request, User $user): RedirectResponse
    {
        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(['user', 'admin', 'moderator'])],
        ]);

        if ($request->user()->role === 'moderator' && $validated['role'] === 'admin') {
            return back()->withErrors(['role' => 'Moderators cannot assign admin role.']);
        }

        $user->update(['role' => $validated['role']]);

        return back()->with('status', 'User role updated.');
    }

    public function banUser(Request $request, User $user): RedirectResponse
    {
        if ($request->user()->id === $user->id) {
            return back()->withErrors(['reason' => 'You cannot ban your own account.']);
        }

        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);

        $user->update([
            'account_status' => 'banned',
            'banned_at' => now(),
            'ban_reason' => $validated['reason'],
        ]);
        $user->tokens()->delete();

        return back()->with('status', 'User banned.');
    }

    public function unbanUser(User $user): RedirectResponse
    {
        $user->update([
            'account_status' => 'active',
            'banned_at' => null,
            'ban_reason' => null,
        ]);

        return back()->with('status', 'User unbanned.');
    }

    public function posts(Request $request): View
    {
        $posts = Post::query()
            ->with(['user', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts', 'reports'])
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.posts.index', ['posts' => $posts]);
    }

    public function deletePost(Post $post): RedirectResponse
    {
        $paths = $post->media()->pluck('path')
            ->when($post->image_path, fn ($collection) => $collection->push($post->image_path))
            ->filter(fn (?string $path): bool => filled($path) && ! str_starts_with($path, 'http'))
            ->unique()
            ->values();

        Storage::disk('public')->delete($paths->all());
        $post->media()->delete();
        $post->delete();

        return back()->with('status', 'Post deleted.');
    }

    public function comments(Request $request): View
    {
        $comments = Comment::query()
            ->with(['user', 'post.user'])
            ->withCount('reports')
            ->latest()
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.comments.index', ['comments' => $comments]);
    }

    public function deleteComment(Comment $comment): RedirectResponse
    {
        $comment->delete();

        return back()->with('status', 'Comment deleted.');
    }

    private function reportsQuery(Request $request)
    {
        $validated = $request->validate([
            'status' => ['sometimes', 'nullable', Rule::in(Report::statuses())],
            'type' => ['sometimes', 'nullable', Rule::in(['post', 'comment', 'user', 'message'])],
            'reason' => ['sometimes', 'nullable', Rule::in(Report::reasons())],
        ]);

        return Report::query()
            ->with(['reporter', 'reviewer', 'reportable'])
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['reason'] ?? null, fn ($query, $reason) => $query->where('reason', $reason))
            ->when($validated['type'] ?? null, fn ($query, $type) => $query->where('reportable_type', $this->classForType($type)))
            ->latest();
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

    private function loadReportableOwner(Report $report): void
    {
        $reportable = $report->reportable;

        if ($reportable instanceof Post || $reportable instanceof Comment) {
            $reportable->loadMissing('user');
        }

        if ($reportable instanceof Message) {
            $reportable->loadMissing('sender');
        }
    }

    private function canAccessAdmin(?User $user): bool
    {
        return in_array($user?->role, ['admin', 'moderator'], true);
    }
}
