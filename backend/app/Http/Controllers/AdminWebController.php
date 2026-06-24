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
            'summary' => [
                'total' => Report::query()->count(),
                'pending' => Report::query()->where('status', Report::STATUS_PENDING)->count(),
                'action_taken' => Report::query()->where('status', Report::STATUS_ACTION_TAKEN)->count(),
                'stale' => Report::query()
                    ->where('status', Report::STATUS_PENDING)
                    ->where('created_at', '<=', now()->subDay())
                    ->count(),
            ],
        ]);
    }

    public function roles(): View
    {
        return view('admin.roles.index', [
            'staff' => User::query()
                ->whereIn('role', ['admin', 'moderator'])
                ->withCount(['reviewedReports', 'posts', 'reports'])
                ->orderByRaw("case role when 'admin' then 0 when 'moderator' then 1 else 2 end")
                ->orderBy('name')
                ->get(),
            'roleCounts' => User::query()
                ->selectRaw('role, count(*) as total')
                ->groupBy('role')
                ->pluck('total', 'role'),
            'permissions' => [
                'admin' => [
                    'Access dashboard analytics',
                    'Review and resolve reports',
                    'Delete posts and comments',
                    'Ban or unban accounts',
                    'Assign admin and moderator roles',
                ],
                'moderator' => [
                    'Access dashboard analytics',
                    'Review and resolve reports',
                    'Delete posts and comments',
                    'Ban or unban non-admin accounts',
                    'Assign moderator or user roles',
                ],
                'user' => [
                    'Use the mobile app',
                    'Create posts, comments, stories, and reports',
                ],
            ],
        ]);
    }

    public function audit(Request $request): View
    {
        $validated = $request->validate([
            'actor' => ['sometimes', 'nullable', 'string', 'max:255'],
            'event' => ['sometimes', 'nullable', Rule::in(['report_review', 'account_ban'])],
            'from' => ['sometimes', 'nullable', 'date'],
            'to' => ['sometimes', 'nullable', 'date'],
        ]);

        $reviewedReports = Report::query()
            ->with(['reviewer', 'reporter'])
            ->whereNotNull('reviewed_at')
            ->when($validated['actor'] ?? null, function ($query, string $actor): void {
                $query->whereHas('reviewer', function ($query) use ($actor): void {
                    $query->where('name', 'like', "%{$actor}%")
                        ->orWhere('email', 'like', "%{$actor}%");
                });
            })
            ->when($validated['event'] ?? null, fn ($query, string $event) => $event === 'report_review' ? $query : $query->whereRaw('1 = 0'))
            ->when($validated['from'] ?? null, fn ($query, string $from) => $query->whereDate('reviewed_at', '>=', $from))
            ->when($validated['to'] ?? null, fn ($query, string $to) => $query->whereDate('reviewed_at', '<=', $to))
            ->latest('reviewed_at')
            ->limit(40)
            ->get()
            ->map(fn (Report $report): array => [
                'type' => 'report_review',
                'label' => 'Report reviewed',
                'actor' => $report->reviewer?->name ?? 'Unknown staff',
                'description' => ucfirst(str_replace('_', ' ', $report->status)).' report #'.$report->id.' for '.class_basename($report->reportable_type).' #'.$report->reportable_id,
                'detail' => $report->action_taken,
                'occurred_at' => $report->reviewed_at,
                'url' => route('admin.reports.show', $report),
            ]);

        $bannedUsers = User::query()
            ->whereNotNull('banned_at')
            ->when($validated['event'] ?? null, fn ($query, string $event) => $event === 'account_ban' ? $query : $query->whereRaw('1 = 0'))
            ->when($validated['from'] ?? null, fn ($query, string $from) => $query->whereDate('banned_at', '>=', $from))
            ->when($validated['to'] ?? null, fn ($query, string $to) => $query->whereDate('banned_at', '<=', $to))
            ->latest('banned_at')
            ->limit(40)
            ->get()
            ->map(fn (User $user): array => [
                'type' => 'account_ban',
                'label' => 'Account banned',
                'actor' => 'Admin staff',
                'description' => $user->name.' was banned',
                'detail' => $user->ban_reason,
                'occurred_at' => $user->banned_at,
                'url' => route('admin.users.show', $user),
            ]);

        $events = $reviewedReports
            ->merge($bannedUsers)
            ->sortByDesc('occurred_at')
            ->values()
            ->take(50);

        return view('admin.audit.index', [
            'events' => $events,
            'summary' => [
                'reviewed_today' => Report::query()->whereDate('reviewed_at', today())->count(),
                'actions_taken' => Report::query()->where('status', Report::STATUS_ACTION_TAKEN)->count(),
                'banned_users' => User::query()->where('account_status', 'banned')->count(),
            ],
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
            'privacy' => ['sometimes', 'nullable', Rule::in(['public', 'private'])],
            'activity' => ['sometimes', 'nullable', Rule::in(['active_24h', 'inactive_30d', 'never_active'])],
            'sort' => ['sometimes', 'nullable', Rule::in(['newest', 'oldest', 'posts', 'followers', 'reports_received'])],
        ]);

        $users = User::query()
            ->withCount(['posts', 'followers', 'following', 'reports', 'receivedReports'])
            ->when($validated['role'] ?? null, fn ($query, $role) => $query->where('role', $role))
            ->when($validated['account_status'] ?? null, fn ($query, $status) => $query->where('account_status', $status))
            ->when($validated['privacy'] ?? null, fn ($query, $privacy) => $query->where('is_private', $privacy === 'private'))
            ->when($validated['activity'] ?? null, function ($query, string $activity): void {
                match ($activity) {
                    'active_24h' => $query->where('last_active_at', '>=', now()->subDay()),
                    'inactive_30d' => $query->where(function ($query): void {
                        $query->whereNull('last_active_at')
                            ->orWhere('last_active_at', '<=', now()->subDays(30));
                    }),
                    'never_active' => $query->whereNull('last_active_at'),
                };
            })
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('username', 'like', "%{$search}%");
                });
            })
            ->when(($validated['sort'] ?? 'newest') === 'oldest', fn ($query) => $query->oldest())
            ->when(($validated['sort'] ?? 'newest') === 'posts', fn ($query) => $query->orderByDesc('posts_count'))
            ->when(($validated['sort'] ?? 'newest') === 'followers', fn ($query) => $query->orderByDesc('followers_count'))
            ->when(($validated['sort'] ?? 'newest') === 'reports_received', fn ($query) => $query->orderByDesc('received_reports_count'))
            ->when(! in_array($validated['sort'] ?? 'newest', ['oldest', 'posts', 'followers', 'reports_received'], true), fn ($query) => $query->latest())
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.users.index', [
            'users' => $users,
            'summary' => [
                'total' => User::query()->count(),
                'admins' => User::query()->where('role', 'admin')->count(),
                'moderators' => User::query()->where('role', 'moderator')->count(),
                'banned' => User::query()->where('account_status', 'banned')->count(),
            ],
        ]);
    }

    public function user(User $user): View
    {
        $user->loadCount(['posts', 'followers', 'following', 'reports', 'receivedReports']);

        return view('admin.users.show', [
            'user' => $user,
            'recentPosts' => $user->posts()
                ->withCount(['likes', 'comments', 'reports'])
                ->latest()
                ->limit(5)
                ->get(),
            'recentReportsMade' => $user->reports()
                ->latest()
                ->limit(5)
                ->get(),
            'recentReportsReceived' => $user->receivedReports()
                ->with('reporter')
                ->latest()
                ->limit(5)
                ->get(),
        ]);
    }

    public function updateUserRole(Request $request, User $user): RedirectResponse
    {
        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(['user', 'admin', 'moderator'])],
        ]);

        if ($request->user()->role === 'moderator' && $validated['role'] === 'admin') {
            return back()->withErrors(['role' => 'Moderators cannot assign admin role.']);
        }

        if ($request->user()->role === 'moderator' && $user->role === 'admin') {
            return back()->withErrors(['role' => 'Moderators cannot change admin accounts.']);
        }

        if ($request->user()->id === $user->id) {
            return back()->withErrors(['role' => 'You cannot change your own role.']);
        }

        $user->update(['role' => $validated['role']]);

        return back()->with('status', 'User role updated.');
    }

    public function banUser(Request $request, User $user): RedirectResponse
    {
        if ($request->user()->id === $user->id) {
            return back()->withErrors(['reason' => 'You cannot ban your own account.']);
        }

        if ($request->user()->role === 'moderator' && $user->role === 'admin') {
            return back()->withErrors(['reason' => 'Moderators cannot ban admin accounts.']);
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
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'author' => ['sometimes', 'nullable', 'string', 'max:255'],
            'reports' => ['sometimes', 'nullable', Rule::in(['with', 'without'])],
            'media' => ['sometimes', 'nullable', Rule::in(['with', 'without'])],
            'from' => ['sometimes', 'nullable', 'date'],
            'to' => ['sometimes', 'nullable', 'date'],
            'sort' => ['sometimes', 'nullable', Rule::in(['newest', 'oldest', 'reports', 'engagement'])],
        ]);

        $posts = Post::query()
            ->with(['user', 'media'])
            ->withCount(['likes', 'comments', 'savedPosts', 'reports'])
            ->when($validated['search'] ?? null, fn ($query, string $search) => $query->where('content', 'like', "%{$search}%"))
            ->when($validated['author'] ?? null, function ($query, string $author): void {
                $query->whereHas('user', function ($query) use ($author): void {
                    $query->where('name', 'like', "%{$author}%")
                        ->orWhere('email', 'like', "%{$author}%")
                        ->orWhere('username', 'like', "%{$author}%");
                });
            })
            ->when($validated['reports'] ?? null, fn ($query, string $reports) => $reports === 'with' ? $query->has('reports') : $query->doesntHave('reports'))
            ->when($validated['media'] ?? null, fn ($query, string $media) => $media === 'with' ? $query->where(fn ($query) => $query->whereNotNull('image_path')->orWhereHas('media')) : $query->whereNull('image_path')->doesntHave('media'))
            ->when($validated['from'] ?? null, fn ($query, string $from) => $query->whereDate('created_at', '>=', $from))
            ->when($validated['to'] ?? null, fn ($query, string $to) => $query->whereDate('created_at', '<=', $to))
            ->when(($validated['sort'] ?? 'newest') === 'oldest', fn ($query) => $query->oldest())
            ->when(($validated['sort'] ?? 'newest') === 'reports', fn ($query) => $query->orderByDesc('reports_count'))
            ->when(($validated['sort'] ?? 'newest') === 'engagement', fn ($query) => $query
                ->orderByDesc('likes_count')
                ->orderByDesc('comments_count')
                ->orderByDesc('saved_posts_count'))
            ->when(! in_array($validated['sort'] ?? 'newest', ['oldest', 'reports', 'engagement'], true), fn ($query) => $query->latest())
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.posts.index', [
            'posts' => $posts,
            'summary' => [
                'total' => Post::query()->count(),
                'reported' => Post::query()->has('reports')->count(),
                'with_media' => Post::query()->where(fn ($query) => $query->whereNotNull('image_path')->orWhereHas('media'))->count(),
                'today' => Post::query()->whereDate('created_at', today())->count(),
            ],
        ]);
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
        $validated = $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'author' => ['sometimes', 'nullable', 'string', 'max:255'],
            'post' => ['sometimes', 'nullable', 'string', 'max:255'],
            'reports' => ['sometimes', 'nullable', Rule::in(['with', 'without'])],
            'from' => ['sometimes', 'nullable', 'date'],
            'to' => ['sometimes', 'nullable', 'date'],
            'sort' => ['sometimes', 'nullable', Rule::in(['newest', 'oldest', 'reports'])],
        ]);

        $comments = Comment::query()
            ->with(['user', 'post.user'])
            ->withCount('reports')
            ->when($validated['search'] ?? null, fn ($query, string $search) => $query->where('comment', 'like', "%{$search}%"))
            ->when($validated['author'] ?? null, function ($query, string $author): void {
                $query->whereHas('user', function ($query) use ($author): void {
                    $query->where('name', 'like', "%{$author}%")
                        ->orWhere('email', 'like', "%{$author}%")
                        ->orWhere('username', 'like', "%{$author}%");
                });
            })
            ->when($validated['post'] ?? null, fn ($query, string $post) => $query->whereHas('post', fn ($query) => $query->where('content', 'like', "%{$post}%")))
            ->when($validated['reports'] ?? null, fn ($query, string $reports) => $reports === 'with' ? $query->has('reports') : $query->doesntHave('reports'))
            ->when($validated['from'] ?? null, fn ($query, string $from) => $query->whereDate('created_at', '>=', $from))
            ->when($validated['to'] ?? null, fn ($query, string $to) => $query->whereDate('created_at', '<=', $to))
            ->when(($validated['sort'] ?? 'newest') === 'oldest', fn ($query) => $query->oldest())
            ->when(($validated['sort'] ?? 'newest') === 'reports', fn ($query) => $query->orderByDesc('reports_count'))
            ->when(! in_array($validated['sort'] ?? 'newest', ['oldest', 'reports'], true), fn ($query) => $query->latest())
            ->paginate(Pagination::perPage($request))
            ->withQueryString();

        return view('admin.comments.index', [
            'comments' => $comments,
            'summary' => [
                'total' => Comment::query()->count(),
                'reported' => Comment::query()->has('reports')->count(),
                'today' => Comment::query()->whereDate('created_at', today())->count(),
            ],
        ]);
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
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'from' => ['sometimes', 'nullable', 'date'],
            'to' => ['sometimes', 'nullable', 'date'],
            'sort' => ['sometimes', 'nullable', Rule::in(['newest', 'oldest', 'stale'])],
        ]);

        return Report::query()
            ->with(['reporter', 'reviewer', 'reportable'])
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['reason'] ?? null, fn ($query, $reason) => $query->where('reason', $reason))
            ->when($validated['type'] ?? null, fn ($query, $type) => $query->where('reportable_type', $this->classForType($type)))
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('description', 'like', "%{$search}%")
                        ->orWhere('action_taken', 'like', "%{$search}%")
                        ->orWhereHas('reporter', function ($query) use ($search): void {
                            $query->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%");
                        });
                });
            })
            ->when($validated['from'] ?? null, fn ($query, string $from) => $query->whereDate('created_at', '>=', $from))
            ->when($validated['to'] ?? null, fn ($query, string $to) => $query->whereDate('created_at', '<=', $to))
            ->when(($validated['sort'] ?? 'newest') === 'oldest', fn ($query) => $query->oldest())
            ->when(($validated['sort'] ?? 'newest') === 'stale', fn ($query) => $query->orderBy('status')->oldest())
            ->when(! in_array($validated['sort'] ?? 'newest', ['oldest', 'stale'], true), fn ($query) => $query->latest());
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
