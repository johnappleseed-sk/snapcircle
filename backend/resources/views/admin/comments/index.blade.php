@extends('admin.layout', ['title' => 'Comments'])

@section('content')
    <div class="mb-5 grid gap-3 sm:grid-cols-3">
        @foreach ([
            ['Total comments', $summary['total']],
            ['Reported', $summary['reported']],
            ['Posted today', $summary['today']],
        ] as [$label, $value])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                <div class="mt-2 text-2xl font-bold text-white">{{ number_format($value) }}</div>
            </div>
        @endforeach
    </div>

    <form method="GET" class="mb-5 rounded-xl border border-white/10 bg-white/[0.04] p-4">
        <div class="grid gap-3 lg:grid-cols-[1.1fr_1fr_1fr_150px]">
            <input name="search" value="{{ request('search') }}" placeholder="Search comment text" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="author" value="{{ request('author') }}" placeholder="Author name, email, username" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="post" value="{{ request('post') }}" placeholder="Parent post content" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="reports" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">Any reports</option>
                <option value="with" @selected(request('reports') === 'with')>With reports</option>
                <option value="without" @selected(request('reports') === 'without')>No reports</option>
            </select>
        </div>
        <div class="mt-3 grid gap-3 md:grid-cols-[160px_160px_160px_1fr_auto_auto]">
            <input name="from" type="date" value="{{ request('from') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="to" type="date" value="{{ request('to') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="sort" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="newest" @selected(request('sort', 'newest') === 'newest')>Newest</option>
                <option value="oldest" @selected(request('sort') === 'oldest')>Oldest</option>
                <option value="reports" @selected(request('sort') === 'reports')>Most reported</option>
            </select>
            <div></div>
            <a href="{{ route('admin.comments.index') }}" class="rounded-lg border border-white/10 px-4 py-2 text-center text-sm font-semibold text-slate-200 hover:bg-white/10">Reset</a>
            <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
        </div>
    </form>

    <div class="overflow-x-auto rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">Comment</th>
                    <th class="px-5 py-3">Author</th>
                    <th class="px-5 py-3">Post</th>
                    <th class="px-5 py-3">Reports</th>
                    <th class="px-5 py-3">Created</th>
                    <th class="px-5 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/10">
                @forelse ($comments as $comment)
                    <tr class="align-top hover:bg-white/[0.03]">
                        <td class="max-w-md px-5 py-4">
                            <div class="line-clamp-3 font-medium text-slate-100">{{ $comment->comment }}</div>
                        </td>
                        <td class="px-5 py-4">
                            @if ($comment->user)
                                <a href="{{ route('admin.users.show', $comment->user) }}" class="text-cyan-300 hover:text-cyan-200">{{ $comment->user->name }}</a>
                                <div class="mt-1 text-slate-500">{{ $comment->user->email }}</div>
                            @else
                                <span class="text-slate-400">Unknown user</span>
                            @endif
                        </td>
                        <td class="max-w-sm px-5 py-4 text-slate-300">
                            <div class="line-clamp-2">{{ $comment->post?->content ?: 'Image-only or deleted post' }}</div>
                            @if ($comment->post?->user)
                                <div class="mt-1 text-xs text-slate-500">By {{ $comment->post->user->name }}</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">
                            <span class="{{ $comment->reports_count > 0 ? 'text-rose-200' : 'text-slate-300' }}">{{ $comment->reports_count }}</span>
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $comment->created_at?->format('M j, Y') }}</td>
                        <td class="px-5 py-4 text-right">
                            <form method="POST" action="{{ route('admin.comments.destroy', $comment) }}" onsubmit="return confirm('Delete this comment?')">
                                @csrf
                                @method('DELETE')
                                <button class="rounded-lg bg-rose-400/90 px-3 py-2 text-xs font-bold text-slate-950 hover:bg-rose-300">Delete</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-5 py-8 text-center text-slate-400">No comments found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $comments->links() }}</div>
@endsection
