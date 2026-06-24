@extends('admin.layout', ['title' => 'Reports'])

@section('content')
    @php
        $statusStyles = [
            'pending' => 'bg-amber-300/10 text-amber-100',
            'reviewed' => 'bg-sky-300/10 text-sky-100',
            'dismissed' => 'bg-slate-300/10 text-slate-200',
            'action_taken' => 'bg-emerald-300/10 text-emerald-100',
        ];
    @endphp

    <div class="mb-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ([
            ['Total reports', $summary['total']],
            ['Pending', $summary['pending']],
            ['Action taken', $summary['action_taken']],
            ['Stale pending', $summary['stale']],
        ] as [$label, $value])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                <div class="mt-2 text-2xl font-bold text-white">{{ number_format($value) }}</div>
            </div>
        @endforeach
    </div>

    <form method="GET" class="mb-5 rounded-xl border border-white/10 bg-white/[0.04] p-4">
        <div class="grid gap-3 lg:grid-cols-[1.2fr_160px_160px_160px]">
            <input name="search" value="{{ request('search') }}" placeholder="Search reporter, description, action taken" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="status" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All statuses</option>
                @foreach ($statuses as $status)
                    <option value="{{ $status }}" @selected(request('status') === $status)>{{ ucfirst(str_replace('_', ' ', $status)) }}</option>
                @endforeach
            </select>
            <select name="reason" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All reasons</option>
                @foreach ($reasons as $reason)
                    <option value="{{ $reason }}" @selected(request('reason') === $reason)>{{ ucfirst(str_replace('_', ' ', $reason)) }}</option>
                @endforeach
            </select>
            <select name="type" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All content types</option>
                @foreach (['post', 'comment', 'user', 'message'] as $type)
                    <option value="{{ $type }}" @selected(request('type') === $type)>{{ ucfirst($type) }}</option>
                @endforeach
            </select>
        </div>
        <div class="mt-3 grid gap-3 md:grid-cols-[160px_160px_160px_1fr_auto_auto]">
            <input name="from" type="date" value="{{ request('from') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="to" type="date" value="{{ request('to') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="sort" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="newest" @selected(request('sort', 'newest') === 'newest')>Newest</option>
                <option value="oldest" @selected(request('sort') === 'oldest')>Oldest</option>
                <option value="stale" @selected(request('sort') === 'stale')>Stale first</option>
            </select>
            <div></div>
            <a href="{{ route('admin.reports.index') }}" class="rounded-lg border border-white/10 px-4 py-2 text-center text-sm font-semibold text-slate-200 hover:bg-white/10">Reset</a>
            <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
        </div>
    </form>

    <div class="overflow-x-auto rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">Reason</th>
                    <th class="px-5 py-3">Target</th>
                    <th class="px-5 py-3">Reporter</th>
                    <th class="px-5 py-3">Status</th>
                    <th class="px-5 py-3">Reviewer</th>
                    <th class="px-5 py-3">Created</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/10">
                @forelse ($reports as $report)
                    <tr class="hover:bg-white/[0.03]">
                        <td class="max-w-sm px-5 py-4">
                            <a href="{{ route('admin.reports.show', $report) }}" class="font-semibold text-cyan-300 hover:text-cyan-200">{{ ucfirst(str_replace('_', ' ', $report->reason)) }}</a>
                            @if ($report->description)
                                <div class="mt-1 truncate text-slate-400">{{ $report->description }}</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">{{ class_basename($report->reportable_type) }} #{{ $report->reportable_id }}</td>
                        <td class="px-5 py-4">
                            <div>{{ $report->reporter?->name ?? 'Unknown' }}</div>
                            <div class="mt-1 text-xs text-slate-500">{{ $report->reporter?->email }}</div>
                        </td>
                        <td class="px-5 py-4">
                            <span class="rounded-full px-3 py-1 text-xs font-semibold {{ $statusStyles[$report->status] ?? 'bg-white/10 text-slate-100' }}">{{ ucfirst(str_replace('_', ' ', $report->status)) }}</span>
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $report->reviewer?->name ?? 'Unassigned' }}</td>
                        <td class="px-5 py-4 text-slate-400">{{ $report->created_at?->diffForHumans() }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-5 py-8 text-center text-slate-400">No reports found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $reports->links() }}</div>
@endsection
