@extends('admin.layout', ['title' => 'Users'])

@section('content')
    <div class="mb-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ([
            ['Total users', $summary['total']],
            ['Admins', $summary['admins']],
            ['Moderators', $summary['moderators']],
            ['Banned', $summary['banned']],
        ] as [$label, $value])
            <div class="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{{ $label }}</div>
                <div class="mt-2 text-2xl font-bold text-white">{{ number_format($value) }}</div>
            </div>
        @endforeach
    </div>

    <form method="GET" class="mb-5 rounded-xl border border-white/10 bg-white/[0.04] p-4">
        <div class="grid gap-3 lg:grid-cols-[1.2fr_150px_170px_150px]">
            <input name="search" value="{{ request('search') }}" placeholder="Search name, email, username" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
            <select name="role" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All roles</option>
                @foreach (['user', 'moderator', 'admin'] as $role)
                    <option value="{{ $role }}" @selected(request('role') === $role)>{{ ucfirst($role) }}</option>
                @endforeach
            </select>
            <select name="account_status" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">All statuses</option>
                @foreach (['active', 'deactivated', 'banned'] as $status)
                    <option value="{{ $status }}" @selected(request('account_status') === $status)>{{ ucfirst($status) }}</option>
                @endforeach
            </select>
            <select name="privacy" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">Any privacy</option>
                <option value="public" @selected(request('privacy') === 'public')>Public</option>
                <option value="private" @selected(request('privacy') === 'private')>Private</option>
            </select>
        </div>
        <div class="mt-3 grid gap-3 md:grid-cols-[170px_190px_1fr_auto_auto]">
            <select name="activity" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="">Any activity</option>
                <option value="active_24h" @selected(request('activity') === 'active_24h')>Active 24h</option>
                <option value="inactive_30d" @selected(request('activity') === 'inactive_30d')>Inactive 30d</option>
                <option value="never_active" @selected(request('activity') === 'never_active')>Never active</option>
            </select>
            <select name="sort" class="rounded-lg border border-white/10 bg-slate-900 px-3 py-2 text-sm">
                <option value="newest" @selected(request('sort', 'newest') === 'newest')>Newest</option>
                <option value="oldest" @selected(request('sort') === 'oldest')>Oldest</option>
                <option value="posts" @selected(request('sort') === 'posts')>Most posts</option>
                <option value="followers" @selected(request('sort') === 'followers')>Most followers</option>
                <option value="reports_received" @selected(request('sort') === 'reports_received')>Most reported</option>
            </select>
            <div></div>
            <a href="{{ route('admin.users.index') }}" class="rounded-lg border border-white/10 px-4 py-2 text-center text-sm font-semibold text-slate-200 hover:bg-white/10">Reset</a>
            <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
        </div>
    </form>

    <div class="mb-5 flex flex-wrap gap-3">
        <a href="{{ route('admin.roles.index') }}" class="rounded-lg bg-white/10 px-4 py-2 text-sm font-semibold text-slate-100 hover:bg-white/15">Manage roles</a>
        <a href="{{ route('admin.users.index', ['account_status' => 'banned']) }}" class="rounded-lg bg-white/10 px-4 py-2 text-sm font-semibold text-slate-100 hover:bg-white/15">View banned users</a>
    </div>

    <div class="overflow-x-auto rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">User</th>
                    <th class="px-5 py-3">Role</th>
                    <th class="px-5 py-3">Status</th>
                    <th class="px-5 py-3">Activity</th>
                    <th class="px-5 py-3">Posts</th>
                    <th class="px-5 py-3">Reports</th>
                    <th class="px-5 py-3">Joined</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/10">
                @forelse ($users as $user)
                    <tr class="hover:bg-white/[0.03]">
                        <td class="px-5 py-4">
                            <a href="{{ route('admin.users.show', $user) }}" class="font-semibold text-cyan-300 hover:text-cyan-200">{{ $user->name }}</a>
                            <div class="mt-1 text-slate-400">{{ $user->email }}</div>
                            @if ($user->username)
                                <div class="mt-1 text-xs text-slate-500">{{ '@'.$user->username }}</div>
                            @endif
                        </td>
                        <td class="px-5 py-4">{{ ucfirst($user->role) }}</td>
                        <td class="px-5 py-4">
                            <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold">{{ ucfirst($user->account_status) }}</span>
                            @if ($user->is_private)
                                <span class="ml-1 rounded-full bg-sky-300/10 px-3 py-1 text-xs font-semibold text-sky-100">Private</span>
                            @endif
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $user->last_active_at?->diffForHumans() ?? 'Never' }}</td>
                        <td class="px-5 py-4">{{ number_format($user->posts_count) }}</td>
                        <td class="px-5 py-4">
                            <div>{{ number_format($user->reports_count) }} made</div>
                            <div class="mt-1 text-xs text-slate-500">{{ number_format($user->received_reports_count) }} received</div>
                        </td>
                        <td class="px-5 py-4 text-slate-400">{{ $user->created_at?->format('M j, Y') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="px-5 py-8 text-center text-slate-400">No users found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $users->links() }}</div>
@endsection
