@extends('admin.layout', ['title' => 'Comments'])

@section('content')
    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/[0.04]">
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
                            <div class="line-clamp-3 font-medium">{{ $comment->comment }}</div>
                        </td>
                        <td class="px-5 py-4">
                            <a href="{{ route('admin.users.show', $comment->user) }}" class="text-cyan-300 hover:text-cyan-200">{{ $comment->user?->name ?? 'Unknown' }}</a>
                            <div class="mt-1 text-slate-500">{{ $comment->user?->email }}</div>
                        </td>
                        <td class="max-w-sm px-5 py-4 text-slate-300">
                            {{ $comment->post?->content ?: 'Image-only or deleted post' }}
                            @if ($comment->post?->user)
                                <div class="mt-1 text-xs text-slate-500">By {{ $comment->post->user->name }}</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">{{ $comment->reports_count }}</td>
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
