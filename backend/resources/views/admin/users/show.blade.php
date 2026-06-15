@extends('admin.layout', ['title' => $user->name])

@section('content')
    <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
        <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
            <div class="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <h2 class="text-2xl font-bold">{{ $user->name }}</h2>
                    <p class="mt-1 text-slate-400">{{ $user->email }}</p>
                    @if ($user->username)
                        <p class="mt-1 text-sm text-slate-500">{{ '@'.$user->username }}</p>
                    @endif
                </div>
                <span class="rounded-full bg-white/10 px-3 py-1 text-sm font-semibold">{{ ucfirst($user->account_status) }}</span>
            </div>

            <div class="mt-6 grid gap-4 md:grid-cols-4">
                @foreach ([
                    ['Posts', $user->posts_count],
                    ['Followers', $user->followers_count],
                    ['Following', $user->following_count],
                    ['Reports made', $user->reports_count],
                ] as [$label, $value])
                    <div class="rounded-lg bg-slate-900/70 p-4">
                        <div class="text-xs uppercase tracking-wider text-slate-500">{{ $label }}</div>
                        <div class="mt-2 text-2xl font-bold">{{ number_format($value) }}</div>
                    </div>
                @endforeach
            </div>

            <div class="mt-6 rounded-lg bg-slate-900/70 p-4">
                <div class="text-xs uppercase tracking-wider text-slate-500">Profile</div>
                <p class="mt-2 text-slate-200">{{ $user->bio ?: 'No bio provided.' }}</p>
                <dl class="mt-4 grid gap-3 text-sm md:grid-cols-2">
                    <div><dt class="text-slate-500">Location</dt><dd>{{ $user->location ?: 'Not set' }}</dd></div>
                    <div><dt class="text-slate-500">Website</dt><dd>{{ $user->website ?: 'Not set' }}</dd></div>
                    <div><dt class="text-slate-500">Role</dt><dd>{{ ucfirst($user->role) }}</dd></div>
                    <div><dt class="text-slate-500">Joined</dt><dd>{{ $user->created_at?->format('M j, Y') }}</dd></div>
                </dl>
            </div>
        </section>

        <aside class="space-y-6">
            <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
                <h2 class="font-semibold">Role</h2>
                <form method="POST" action="{{ route('admin.users.role', $user) }}" class="mt-4 space-y-4">
                    @csrf
                    @method('PUT')
                    <select name="role" class="w-full rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                        @foreach (['user', 'moderator', 'admin'] as $role)
                            <option value="{{ $role }}" @selected($user->role === $role)>{{ ucfirst($role) }}</option>
                        @endforeach
                    </select>
                    <button class="w-full rounded-lg bg-cyan-400 px-4 py-2.5 text-sm font-bold text-slate-950">Update role</button>
                </form>
            </section>

            <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
                <h2 class="font-semibold">Account status</h2>
                @if ($user->account_status === 'banned')
                    <p class="mt-3 text-sm text-slate-400">Reason: {{ $user->ban_reason ?: 'No reason recorded.' }}</p>
                    <form method="POST" action="{{ route('admin.users.unban', $user) }}" class="mt-4">
                        @csrf
                        @method('PUT')
                        <button class="w-full rounded-lg bg-emerald-400 px-4 py-2.5 text-sm font-bold text-slate-950">Unban user</button>
                    </form>
                @else
                    <form method="POST" action="{{ route('admin.users.ban', $user) }}" class="mt-4 space-y-4">
                        @csrf
                        @method('PUT')
                        <textarea name="reason" rows="4" required placeholder="Reason for ban" class="w-full rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm"></textarea>
                        <button class="w-full rounded-lg bg-rose-400 px-4 py-2.5 text-sm font-bold text-slate-950">Ban user</button>
                    </form>
                @endif
            </section>
        </aside>
    </div>
@endsection
