@extends('admin.layout', ['title' => 'Dashboard'])

@section('content')
    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ([
            ['Users', $stats['total_users'], 'Active '.$stats['active_users']],
            ['Posts', $stats['total_posts'], $stats['new_posts_today'].' today'],
            ['Comments', $stats['total_comments'], 'Across all posts'],
            ['Pending reports', $stats['pending_reports'], $stats['reports_today'].' today'],
            ['Banned users', $stats['banned_users'], 'Moderation actions'],
            ['Stories', $stats['total_stories'], 'Story posts'],
            ['Messages', $stats['total_messages'], 'Chat volume'],
            ['New users', $stats['new_users_today'], 'Today'],
        ] as [$label, $value, $hint])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
                <div class="text-sm text-slate-400">{{ $label }}</div>
                <div class="mt-3 text-3xl font-bold">{{ number_format($value) }}</div>
                <div class="mt-2 text-xs text-slate-500">{{ $hint }}</div>
            </div>
        @endforeach
    </div>

    <div class="mt-8 grid gap-6 xl:grid-cols-[1fr_360px]">
        <section class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex items-center justify-between border-b border-white/10 px-5 py-4">
                <h2 class="font-semibold">Recent reports</h2>
                <a href="{{ route('admin.reports.index') }}" class="text-sm font-semibold text-cyan-300 hover:text-cyan-200">View all</a>
            </div>
            <div class="divide-y divide-white/10">
                @forelse ($recentReports as $report)
                    <a href="{{ route('admin.reports.show', $report) }}" class="block px-5 py-4 hover:bg-white/[0.03]">
                        <div class="flex items-center justify-between gap-4">
                            <div>
                                <div class="font-medium">{{ ucfirst(str_replace('_', ' ', $report->reason)) }}</div>
                                <div class="mt-1 text-sm text-slate-400">Reported by {{ $report->reporter?->name ?? 'Unknown user' }}</div>
                            </div>
                            <span class="rounded-full bg-amber-400/10 px-3 py-1 text-xs font-semibold text-amber-200">{{ $report->status }}</span>
                        </div>
                    </a>
                @empty
                    <div class="px-5 py-8 text-sm text-slate-400">No reports yet.</div>
                @endforelse
            </div>
        </section>

        <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <h2 class="font-semibold">Quick actions</h2>
            <div class="mt-4 grid gap-3">
                <a href="{{ route('admin.reports.index', ['status' => 'pending']) }}" class="rounded-lg bg-white/10 px-4 py-3 text-sm font-semibold hover:bg-white/15">Review pending reports</a>
                <a href="{{ route('admin.users.index') }}" class="rounded-lg bg-white/10 px-4 py-3 text-sm font-semibold hover:bg-white/15">Manage users</a>
                <a href="{{ route('admin.posts.index') }}" class="rounded-lg bg-white/10 px-4 py-3 text-sm font-semibold hover:bg-white/15">Moderate posts</a>
                <a href="{{ route('admin.comments.index') }}" class="rounded-lg bg-white/10 px-4 py-3 text-sm font-semibold hover:bg-white/15">Moderate comments</a>
            </div>
        </section>
    </div>
@endsection
