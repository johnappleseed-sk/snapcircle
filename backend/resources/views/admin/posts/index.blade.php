@extends('admin.layout', ['title' => 'Posts'])

@section('content')
    <div class="mb-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ([
            ['Total posts', $summary['total']],
            ['Reported', $summary['reported']],
            ['With media', $summary['with_media']],
            ['Posted today', $summary['today']],
        ] as [$label, $value])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                <div class="mt-2 text-2xl font-bold text-white">{{ number_format($value) }}</div>
            </div>
        @endforeach
    </div>

    <form method="GET" class="mb-5 rounded-xl border border-white/10 bg-white/[0.04] p-4">
        <div class="grid gap-3 lg:grid-cols-[1.2fr_1fr_150px_150px]">
            <input name="search" value="{{ request('search') }}" placeholder="Search post content" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="author" value="{{ request('author') }}" placeholder="Author name, email, username" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="reports" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">Any reports</option>
                <option value="with" @selected(request('reports') === 'with')>With reports</option>
                <option value="without" @selected(request('reports') === 'without')>No reports</option>
            </select>
            <select name="media" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">Any media</option>
                <option value="with" @selected(request('media') === 'with')>With media</option>
                <option value="without" @selected(request('media') === 'without')>Text only</option>
            </select>
        </div>
        <div class="mt-3 grid gap-3 md:grid-cols-[160px_160px_170px_1fr_auto_auto]">
            <input name="from" type="date" value="{{ request('from') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <input name="to" type="date" value="{{ request('to') }}" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="sort" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="newest" @selected(request('sort', 'newest') === 'newest')>Newest</option>
                <option value="oldest" @selected(request('sort') === 'oldest')>Oldest</option>
                <option value="reports" @selected(request('sort') === 'reports')>Most reported</option>
                <option value="engagement" @selected(request('sort') === 'engagement')>Most engaged</option>
            </select>
            <div></div>
            <a href="{{ route('admin.posts.index') }}" class="rounded-lg border border-white/10 px-4 py-2 text-center text-sm font-semibold text-slate-200 hover:bg-white/10">Reset</a>
            <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
        </div>
    </form>

    <div class="overflow-x-auto rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">Post</th>
                    <th class="px-5 py-3">Author</th>
                    <th class="px-5 py-3">Engagement</th>
                    <th class="px-5 py-3">Reports</th>
                    <th class="px-5 py-3">Created</th>
                    <th class="px-5 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/10">
                @forelse ($posts as $post)
                    <tr class="align-top hover:bg-white/[0.03]">
                        <td class="max-w-xl px-5 py-4">
                            <div class="line-clamp-3 font-medium text-slate-100">{{ $post->content ?: 'Image-only post' }}</div>
                            <div class="mt-2 flex flex-wrap gap-2 text-xs text-slate-500">
                                @if ($post->media->isNotEmpty())
                                    <span>{{ $post->media->count() }} media item(s)</span>
                                @endif
                                @if ($post->image_path)
                                    <span>legacy image</span>
                                @endif
                            </div>
                        </td>
                        <td class="px-5 py-4">
                            @if ($post->user)
                                <a href="{{ route('admin.users.show', $post->user) }}" class="text-cyan-300 hover:text-cyan-200">{{ $post->user->name }}</a>
                                <div class="mt-1 text-slate-500">{{ $post->user->email }}</div>
                            @else
                                <span class="text-slate-400">Unknown user</span>
                            @endif
                        </td>
                        <td class="px-5 py-4 text-slate-300">
                            {{ $post->likes_count }} likes<br>
                            {{ $post->comments_count }} comments<br>
                            {{ $post->saved_posts_count }} saves
                        </td>
                        <td class="px-5 py-4">
                            <span class="{{ $post->reports_count > 0 ? 'text-rose-200' : 'text-slate-300' }}">{{ $post->reports_count }}</span>
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $post->created_at?->format('M j, Y') }}</td>
                        <td class="px-5 py-4 text-right">
                            <form method="POST" action="{{ route('admin.posts.destroy', $post) }}" onsubmit="return confirm('Delete this post?')">
                                @csrf
                                @method('DELETE')
                                <button class="rounded-lg bg-rose-400/90 px-3 py-2 text-xs font-bold text-slate-950 hover:bg-rose-300">Delete</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-5 py-8 text-center text-slate-400">No posts found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $posts->links() }}</div>
@endsection
