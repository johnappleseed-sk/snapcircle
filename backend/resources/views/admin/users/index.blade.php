@extends('admin.layout', ['title' => 'Users'])

@section('content')
    <form method="GET" class="mb-5 grid gap-3 rounded-xl border border-white/10 bg-white/[0.04] p-4 lg:grid-cols-[1fr_180px_180px_120px]">
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
        <button class="rounded-lg bg-cyan-400 px-4 py-2 text-sm font-bold text-slate-950">Filter</button>
    </form>

    <div class="overflow-hidden rounded-xl border border-white/10 bg-white/[0.04]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
            <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                <tr>
                    <th class="px-5 py-3">User</th>
                    <th class="px-5 py-3">Role</th>
                    <th class="px-5 py-3">Status</th>
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
                        </td>
                        <td class="px-5 py-4">{{ ucfirst($user->role) }}</td>
                        <td class="px-5 py-4">
                            <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold">{{ ucfirst($user->account_status) }}</span>
                        </td>
                        <td class="px-5 py-4">{{ number_format($user->posts_count) }}</td>
                        <td class="px-5 py-4">{{ number_format($user->reports_count) }}</td>
                        <td class="px-5 py-4 text-slate-400">{{ $user->created_at?->format('M j, Y') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-5 py-8 text-center text-slate-400">No users found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-5">{{ $users->links() }}</div>
@endsection
