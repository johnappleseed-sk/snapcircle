@extends('admin.layout', ['title' => 'Dashboard'])

@section('content')
    @php
        $maxActivity = max(1, $activitySeries->flatMap(fn ($day) => [$day['users'], $day['posts'], $day['reports']])->max() ?? 1);
        $statusStyles = [
            'pending' => 'border-amber-300/30 bg-amber-300/10 text-amber-100',
            'reviewed' => 'border-sky-300/30 bg-sky-300/10 text-sky-100',
            'dismissed' => 'border-slate-300/20 bg-slate-300/10 text-slate-200',
            'action_taken' => 'border-emerald-300/30 bg-emerald-300/10 text-emerald-100',
        ];
    @endphp

    <section class="grid gap-4 xl:grid-cols-[1.5fr_1fr]">
        <div class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <p class="text-sm font-medium text-cyan-200">Moderation command center</p>
                    <h2 class="mt-2 text-2xl font-bold tracking-tight text-white">Keep SnapCircle healthy today</h2>
                    <p class="mt-2 max-w-2xl text-sm text-slate-400">
                        {{ number_format($stats['pending_reports']) }} pending reports,
                        {{ number_format($stats['pending_older_than_day']) }} older than 24 hours,
                        and {{ number_format($stats['active_last_24h']) }} users active in the last day.
                    </p>
                </div>
                <div class="flex gap-2">
                    <a href="{{ route('admin.reports.index', ['status' => 'pending']) }}" class="rounded-lg bg-cyan-300 px-4 py-2 text-sm font-bold text-slate-950 hover:bg-cyan-200">Review queue</a>
                    <a href="{{ route('admin.users.index', ['account_status' => 'banned']) }}" class="rounded-lg border border-white/10 px-4 py-2 text-sm font-semibold text-slate-100 hover:bg-white/10">Bans</a>
                </div>
            </div>

            <div class="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                @foreach ([
                    ['Users', $stats['total_users'], $stats['new_users_today'].' joined today'],
                    ['Posts', $stats['total_posts'], $stats['new_posts_today'].' posted today'],
                    ['Reports', $stats['total_reports'], $stats['reports_today'].' filed today'],
                    ['Resolution', $stats['resolution_rate'].'%', $stats['reviewed_today'].' reviewed today'],
                ] as [$label, $value, $hint])
                    <div class="rounded-lg border border-white/10 bg-slate-950/45 p-4">
                        <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                        <div class="mt-3 text-3xl font-bold text-white">{{ is_numeric($value) ? number_format($value) : $value }}</div>
                        <div class="mt-2 text-xs text-slate-400">{{ $hint }}</div>
                    </div>
                @endforeach
            </div>
        </div>

        <div class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex items-center justify-between gap-4">
                <div>
                    <h2 class="font-semibold text-white">Queue health</h2>
                    <p class="mt-1 text-sm text-slate-400">Current report states</p>
                </div>
                @if ($oldestPendingReport)
                    <a href="{{ route('admin.reports.show', $oldestPendingReport) }}" class="rounded-lg bg-amber-300/15 px-3 py-2 text-xs font-bold text-amber-100 hover:bg-amber-300/20">Oldest pending</a>
                @endif
            </div>

            <div class="mt-5 space-y-3">
                @foreach ($statusCounts as $status => $count)
                    @php
                        $total = max(1, $statusCounts->sum());
                        $percent = round(($count / $total) * 100);
                    @endphp
                    <a href="{{ route('admin.reports.index', ['status' => $status]) }}" class="block rounded-lg border px-4 py-3 {{ $statusStyles[$status] ?? 'border-white/10 bg-white/5 text-slate-100' }}">
                        <div class="flex items-center justify-between text-sm font-semibold">
                            <span>{{ ucfirst(str_replace('_', ' ', $status)) }}</span>
                            <span>{{ number_format($count) }}</span>
                        </div>
                        <div class="mt-2 h-1.5 rounded-full bg-slate-950/50">
                            <div class="h-1.5 rounded-full bg-current" style="width: {{ $percent }}%"></div>
                        </div>
                    </a>
                @endforeach
            </div>
        </div>
    </section>

    <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_380px]">
        <div class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex items-center justify-between gap-4">
                <div>
                    <h2 class="font-semibold text-white">Seven-day activity</h2>
                    <p class="mt-1 text-sm text-slate-400">New users, posts, and reports by day</p>
                </div>
                <div class="flex gap-3 text-xs text-slate-400">
                    <span><span class="mr-1 inline-block h-2 w-2 rounded-full bg-cyan-300"></span>Users</span>
                    <span><span class="mr-1 inline-block h-2 w-2 rounded-full bg-violet-300"></span>Posts</span>
                    <span><span class="mr-1 inline-block h-2 w-2 rounded-full bg-amber-300"></span>Reports</span>
                </div>
            </div>

            <div class="mt-6 grid min-h-64 grid-cols-7 items-end gap-3">
                @foreach ($activitySeries as $day)
                    <div class="flex h-56 flex-col justify-end gap-1">
                        <div class="flex flex-1 items-end justify-center gap-1 rounded-lg bg-slate-950/35 px-2 pb-2">
                            <div title="{{ $day['users'] }} users" class="w-2 rounded-t bg-cyan-300" style="height: {{ max(4, ($day['users'] / $maxActivity) * 100) }}%"></div>
                            <div title="{{ $day['posts'] }} posts" class="w-2 rounded-t bg-violet-300" style="height: {{ max(4, ($day['posts'] / $maxActivity) * 100) }}%"></div>
                            <div title="{{ $day['reports'] }} reports" class="w-2 rounded-t bg-amber-300" style="height: {{ max(4, ($day['reports'] / $maxActivity) * 100) }}%"></div>
                        </div>
                        <div class="text-center text-xs text-slate-500">{{ $day['label'] }}</div>
                    </div>
                @endforeach
            </div>
        </div>

        <div class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex items-center justify-between gap-4">
                <div>
                    <h2 class="font-semibold text-white">Top report reasons</h2>
                    <p class="mt-1 text-sm text-slate-400">Most common flags</p>
                </div>
                <a href="{{ route('admin.reports.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">All reports</a>
            </div>

            <div class="mt-5 space-y-4">
                @forelse ($reasonCounts as $reason => $count)
                    @php
                        $percent = round(($count / max(1, $reasonCounts->max())) * 100);
                    @endphp
                    <a href="{{ route('admin.reports.index', ['reason' => $reason]) }}" class="block">
                        <div class="flex items-center justify-between text-sm">
                            <span class="font-medium text-slate-200">{{ ucfirst(str_replace('_', ' ', $reason)) }}</span>
                            <span class="text-slate-400">{{ number_format($count) }}</span>
                        </div>
                        <div class="mt-2 h-2 rounded-full bg-slate-950/70">
                            <div class="h-2 rounded-full bg-cyan-300" style="width: {{ $percent }}%"></div>
                        </div>
                    </a>
                @empty
                    <div class="rounded-lg border border-dashed border-white/10 px-4 py-8 text-center text-sm text-slate-400">No reports yet.</div>
                @endforelse
            </div>
        </div>
    </section>

    <section class="mt-6 grid gap-6 xl:grid-cols-3">
        <div class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold text-white">Recent reports</h2>
                <a href="{{ route('admin.reports.index', ['status' => 'pending']) }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">Queue</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($recentReports as $report)
                    <a href="{{ route('admin.reports.show', $report) }}" class="block px-5 py-4 hover:bg-white/[0.03]">
                        <div class="flex items-start justify-between gap-4">
                            <div class="min-w-0">
                                <div class="truncate font-medium text-white">{{ ucfirst(str_replace('_', ' ', $report->reason)) }}</div>
                                <div class="mt-1 text-sm text-slate-400">{{ class_basename($report->reportable_type) }} #{{ $report->reportable_id }}</div>
                            </div>
                            <span class="shrink-0 rounded-full bg-amber-300/10 px-3 py-1 text-xs font-semibold text-amber-100">{{ $report->status }}</span>
                        </div>
                    </a>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No reports yet.</div>
                @endforelse
            </div>
        </div>

        <div class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold text-white">Fresh posts</h2>
                <a href="{{ route('admin.posts.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">Moderate</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($recentPosts as $post)
                    <div class="px-5 py-4">
                        <div class="line-clamp-2 text-sm font-medium text-slate-100">{{ $post->content ?: 'Image-only post' }}</div>
                        <div class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                            <a href="{{ $post->user ? route('admin.users.show', $post->user) : '#' }}" class="text-cyan-300 hover:text-cyan-200">{{ $post->user?->name ?? 'Unknown' }}</a>
                            <span>{{ $post->likes_count }} likes</span>
                            <span>{{ $post->comments_count }} comments</span>
                            <span>{{ $post->reports_count }} reports</span>
                        </div>
                    </div>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No posts yet.</div>
                @endforelse
            </div>
        </div>

        <div class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold text-white">New members</h2>
                <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">Users</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($recentUsers as $user)
                    <a href="{{ route('admin.users.show', $user) }}" class="block px-5 py-4 hover:bg-white/[0.03]">
                        <div class="flex items-center justify-between gap-4">
                            <div class="min-w-0">
                                <div class="truncate font-medium text-white">{{ $user->name }}</div>
                                <div class="mt-1 truncate text-sm text-slate-400">{{ $user->email }}</div>
                            </div>
                            <span class="shrink-0 rounded-full bg-white/10 px-3 py-1 text-xs font-semibold text-slate-200">{{ $user->posts_count }} posts</span>
                        </div>
                    </a>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No users yet.</div>
                @endforelse
            </div>
        </div>
    </section>

    <section class="mt-6 grid gap-6 xl:grid-cols-2">
        <div class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold text-white">Recent comments</h2>
                <a href="{{ route('admin.comments.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">Review</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($recentComments as $comment)
                    <div class="px-5 py-4">
                        <div class="line-clamp-2 text-sm text-slate-100">{{ $comment->comment }}</div>
                        <div class="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-500">
                            <span>{{ $comment->user?->name ?? 'Unknown user' }}</span>
                            <span>on {{ $comment->post?->user?->name ?? 'unknown author' }}'s post</span>
                            <span>{{ $comment->reports_count }} reports</span>
                        </div>
                    </div>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No comments yet.</div>
                @endforelse
            </div>
        </div>

        <div class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold text-white">Reported users</h2>
                <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">Manage</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($flaggedUsers as $user)
                    <a href="{{ route('admin.users.show', $user) }}" class="block px-5 py-4 hover:bg-white/[0.03]">
                        <div class="flex items-center justify-between gap-4">
                            <div class="min-w-0">
                                <div class="truncate font-medium text-white">{{ $user->name }}</div>
                                <div class="mt-1 truncate text-sm text-slate-400">{{ ucfirst($user->account_status) }} account</div>
                            </div>
                            <span class="shrink-0 rounded-full bg-rose-300/10 px-3 py-1 text-xs font-semibold text-rose-100">{{ $user->received_reports_count }} reports</span>
                        </div>
                    </a>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No users have been reported.</div>
                @endforelse
            </div>
        </div>
    </section>
@endsection
