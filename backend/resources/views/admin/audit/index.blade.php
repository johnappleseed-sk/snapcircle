@extends('admin.layout', ['title' => 'Audit'])

@section('content')
    <div class="mb-5 grid gap-3 sm:grid-cols-3">
        @foreach ([
            ['Reviewed today', $summary['reviewed_today']],
            ['Actions taken', $summary['actions_taken']],
            ['Banned users', $summary['banned_users']],
        ] as [$label, $value])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                <div class="mt-2 text-2xl font-bold text-white">{{ number_format($value) }}</div>
            </div>
        @endforeach
    </div>

    <form method="GET" class="mb-5 rounded-xl border border-white/10 bg-white/[0.04] p-4">
        <div class="grid gap-3 md:grid-cols-[1fr_180px_160px_160px_auto_auto]">
            <input name="actor" value="{{ request('actor') }}" placeholder="Search reviewer name or email" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="event" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All events</option>
                <option value="report_review" @selected(request('event') === 'report_review')>Report reviews</option>
                <option value="account_ban" @selected(request('event') === 'account_ban')>Account bans</option>
            </select>
            <input name="from" type="date" value="{{ request('from') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="to" type="date" value="{{ request('to') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <a href="{{ route('admin.audit.index') }}" class="rounded-lg border border-white/10 px-4 py-2 text-center text-sm font-semibold text-slate-200 hover:bg-white/10">Reset</a>
            <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
        </div>
    </form>

    <section class="rounded-xl border border-white/10 bg-white/[0.04]">
        <div class="border-b border-white/10 px-5 py-4">
            <h2 class="font-semibold text-white">Recent admin activity</h2>
            <p class="mt-1 text-sm text-slate-400">Report review decisions and account bans from existing moderation data</p>
        </div>
        <div class="divide-y divide-white/10">
            @forelse ($events as $event)
                <a href="{{ $event['url'] }}" class="block px-5 py-4 hover:bg-white/[0.03]">
                    <div class="flex flex-wrap items-start justify-between gap-4">
                        <div class="min-w-0">
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="font-semibold text-white">{{ $event['label'] }}</span>
                                <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold text-slate-200">{{ str_replace('_', ' ', $event['type']) }}</span>
                            </div>
                            <div class="mt-1 text-sm text-slate-300">{{ $event['description'] }}</div>
                            @if ($event['detail'])
                                <div class="mt-1 line-clamp-2 text-sm text-slate-500">{{ $event['detail'] }}</div>
                            @endif
                        </div>
                        <div class="text-right text-sm text-slate-400">
                            <div>{{ $event['actor'] }}</div>
                            <div class="mt-1 text-xs text-slate-500">{{ $event['occurred_at']?->diffForHumans() }}</div>
                        </div>
                    </div>
                </a>
            @empty
                <div class="px-5 py-8 text-center text-sm text-slate-400">No audit events found.</div>
            @endforelse
        </div>
    </section>
@endsection
