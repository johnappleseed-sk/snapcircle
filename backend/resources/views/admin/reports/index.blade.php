@extends('admin.layout', ['title' => 'Reports'])

@section('content')
    <form method="GET" class="mb-5 grid gap-3 rounded-xl border border-white/10 bg-white/[0.04] p-4 md:grid-cols-4">
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
        <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
    </form>

    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">Reason</th>
                    <th class="px-5 py-3">Target</th>
                    <th class="px-5 py-3">Reporter</th>
                    <th class="px-5 py-3">Status</th>
                    <th class="px-5 py-3">Created</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/10">
                @forelse ($reports as $report)
                    <tr class="hover:bg-white/[0.03]">
                        <td class="px-5 py-4">
                            <a href="{{ route('admin.reports.show', $report) }}" class="font-semibold text-cyan-300 hover:text-cyan-200">{{ ucfirst(str_replace('_', ' ', $report->reason)) }}</a>
                            @if ($report->description)
                                <div class="mt-1 max-w-xs truncate text-slate-400">{{ $report->description }}</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">{{ class_basename($report->reportable_type) }} #{{ $report->reportable_id }}</td>
                        <td class="px-5 py-4">{{ $report->reporter?->name ?? 'Unknown' }}</td>
                        <td class="px-5 py-4">
                            <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold">{{ ucfirst(str_replace('_', ' ', $report->status)) }}</span>
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $report->created_at?->diffForHumans() }}</td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="px-5 py-8 text-center text-slate-400">No reports found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $reports->links() }}</div>
@endsection
