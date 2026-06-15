@extends('admin.layout', ['title' => 'Report #'.$report->id])

@section('content')
    <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
        <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <div class="text-sm text-slate-400">Reason</div>
                    <h2 class="mt-1 text-2xl font-bold">{{ ucfirst(str_replace('_', ' ', $report->reason)) }}</h2>
                </div>
                <span class="rounded-full bg-white/10 px-3 py-1 text-sm font-semibold">{{ ucfirst(str_replace('_', ' ', $report->status)) }}</span>
            </div>

            <dl class="mt-6 grid gap-4 md:grid-cols-2">
                <div class="rounded-lg bg-slate-900/70 p-4">
                    <dt class="text-xs uppercase tracking-wider text-slate-500">Reporter</dt>
                    <dd class="mt-1 font-medium">{{ $report->reporter?->name ?? 'Unknown' }}</dd>
                    <dd class="text-sm text-slate-400">{{ $report->reporter?->email }}</dd>
                </div>
                <div class="rounded-lg bg-slate-900/70 p-4">
                    <dt class="text-xs uppercase tracking-wider text-slate-500">Target</dt>
                    <dd class="mt-1 font-medium">{{ class_basename($report->reportable_type) }} #{{ $report->reportable_id }}</dd>
                    <dd class="text-sm text-slate-400">Created {{ $report->created_at?->diffForHumans() }}</dd>
                </div>
            </dl>

            <div class="mt-6 rounded-lg bg-slate-900/70 p-4">
                <div class="text-xs uppercase tracking-wider text-slate-500">Description</div>
                <p class="mt-2 whitespace-pre-line text-slate-200">{{ $report->description ?: 'No description provided.' }}</p>
            </div>

            <div class="mt-6 rounded-lg bg-slate-900/70 p-4">
                <div class="text-xs uppercase tracking-wider text-slate-500">Reported content</div>
                @php($target = $report->reportable)
                @if ($target instanceof \App\Models\Post)
                    <p class="mt-2 whitespace-pre-line">{{ $target->content ?: 'Image-only post' }}</p>
                    <p class="mt-3 text-sm text-slate-400">By {{ $target->user?->name ?? 'Unknown user' }}</p>
                @elseif ($target instanceof \App\Models\Comment)
                    <p class="mt-2 whitespace-pre-line">{{ $target->comment }}</p>
                    <p class="mt-3 text-sm text-slate-400">By {{ $target->user?->name ?? 'Unknown user' }}</p>
                @elseif ($target instanceof \App\Models\User)
                    <p class="mt-2 font-medium">{{ $target->name }}</p>
                    <p class="text-sm text-slate-400">{{ $target->email }}</p>
                @elseif ($target instanceof \App\Models\Message)
                    <p class="mt-2 whitespace-pre-line">{{ $target->body ?? $target->message ?? 'Message content unavailable' }}</p>
                    <p class="mt-3 text-sm text-slate-400">By {{ $target->sender?->name ?? 'Unknown user' }}</p>
                @else
                    <p class="mt-2 text-slate-400">The reported item is no longer available.</p>
                @endif
            </div>
        </section>

        <aside class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <h2 class="font-semibold">Review decision</h2>
            <form method="POST" action="{{ route('admin.reports.update', $report) }}" class="mt-4 space-y-4">
                @csrf
                @method('PUT')
                <div>
                    <label class="text-sm font-medium text-slate-300">Status</label>
                    <select name="status" class="mt-2 w-full rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                        @foreach ($statuses as $status)
                            <option value="{{ $status }}" @selected($report->status === $status)>{{ ucfirst(str_replace('_', ' ', $status)) }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="text-sm font-medium text-slate-300">Action taken</label>
                    <textarea name="action_taken" rows="4" class="mt-2 w-full rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">{{ old('action_taken', $report->action_taken) }}</textarea>
                </div>
                <button class="w-full rounded-lg bg-cyan-400 px-4 py-2.5 text-sm font-bold text-slate-950">Save review</button>
            </form>
        </aside>
    </div>
@endsection
