@extends('admin.layout', ['title' => 'Roles'])

@section('content')
    <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
        <section class="rounded-xl border border-white/10 bg-white/[0.04]">
            <div class="flex flex-wrap items-center justify-between gap-4 border-b border-white/10 px-5 py-4">
                <div>
                    <h2 class="font-semibold text-white">Staff accounts</h2>
                    <p class="mt-1 text-sm text-slate-400">Admins and moderators with management access</p>
                </div>
                <a href="{{ route('admin.users.index', ['role' => 'moderator']) }}" class="rounded-lg bg-white/10 px-4 py-2 text-sm font-semibold hover:bg-white/15">View moderators</a>
            </div>

            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-white/10 text-sm">
                    <thead class="bg-white/[0.03] text-left text-xs uppercase tracking-wider text-slate-400">
                        <tr>
                            <th class="px-5 py-3">Staff member</th>
                            <th class="px-5 py-3">Role</th>
                            <th class="px-5 py-3">Reviews</th>
                            <th class="px-5 py-3">Reports made</th>
                            <th class="px-5 py-3">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/10">
                        @forelse ($staff as $user)
                            <tr class="hover:bg-white/[0.03]">
                                <td class="px-5 py-4">
                                    <a href="{{ route('admin.users.show', $user) }}" class="font-semibold text-cyan-300 hover:text-cyan-200">{{ $user->name }}</a>
                                    <div class="mt-1 text-slate-400">{{ $user->email }}</div>
                                </td>
                                <td class="px-5 py-4">{{ ucfirst($user->role) }}</td>
                                <td class="px-5 py-4">{{ number_format($user->reviewed_reports_count) }}</td>
                                <td class="px-5 py-4">{{ number_format($user->reports_count) }}</td>
                                <td class="px-5 py-4">
                                    <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold">{{ ucfirst($user->account_status) }}</span>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="px-5 py-8 text-center text-slate-400">No staff accounts found.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </section>

        <aside class="space-y-6">
            <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
                <h2 class="font-semibold text-white">Role distribution</h2>
                <div class="mt-4 space-y-3">
                    @foreach (['admin', 'moderator', 'user'] as $role)
                        <a href="{{ route('admin.users.index', ['role' => $role]) }}" class="flex items-center justify-between rounded-lg bg-slate-950/45 px-4 py-3 text-sm hover:bg-slate-900">
                            <span>{{ ucfirst($role) }}</span>
                            <span class="font-semibold">{{ number_format($roleCounts[$role] ?? 0) }}</span>
                        </a>
                    @endforeach
                </div>
            </section>

            <section class="rounded-xl border border-white/10 bg-white/[0.04] p-5">
                <h2 class="font-semibold text-white">Permission matrix</h2>
                <div class="mt-4 space-y-4">
                    @foreach ($permissions as $role => $items)
                        <div class="rounded-lg border border-white/10 bg-slate-950/40 p-4">
                            <div class="font-semibold">{{ ucfirst($role) }}</div>
                            <ul class="mt-3 space-y-2 text-sm text-slate-400">
                                @foreach ($items as $item)
                                    <li>{{ $item }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endforeach
                </div>
            </section>
        </aside>
    </div>
@endsection
