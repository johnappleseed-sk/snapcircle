@extends('admin.layout', ['title' => 'Posts'])

@section('content')
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/[0.04]">
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
                            <div class="line-clamp-3 font-medium">{{ $post->content ?: 'Image-only post' }}</div>
                            @if ($post->media->isNotEmpty())
                                <div class="mt-2 text-xs text-slate-400">{{ $post->media->count() }} media item(s)</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">
                            <a href="{{ route('admin.users.show', $post->user) }}" class="text-cyan-300 hover:text-cyan-200">{{ $post->user?->name ?? 'Unknown' }}</a>
                            <div class="mt-1 text-slate-500">{{ $post->user?->email }}</div>
                        </td>
                        <td class="px-5 py-4 text-slate-300">
                            {{ $post->likes_count }} likes<br>
                            {{ $post->comments_count }} comments<br>
                            {{ $post->saved_posts_count }} saves
                        </td>
                        <td class="px-5 py-4">{{ $post->reports_count }}</td>
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
