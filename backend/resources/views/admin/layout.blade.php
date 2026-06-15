<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'SnapCircle Admin' }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen bg-slate-950 text-slate-100 antialiased">
    <div class="flex min-h-screen">
        @auth
            <aside class="hidden w-72 border-r border-white/10 bg-slate-900/80 p-6 lg:block">
                <a href="{{ route('admin.dashboard') }}" class="block">
                    <div class="text-xl font-bold tracking-tight">SnapCircle</div>
                    <div class="mt-1 text-sm text-slate-400">Moderation Console</div>
                </a>

                <nav class="mt-10 space-y-1">
                    @php
                        $items = [
                            ['Dashboard', 'admin.dashboard', 'M3 6h18M3 12h18M3 18h18'],
                            ['Reports', 'admin.reports.index', 'M12 9v4m0 4h.01M10.29 3.86 1.42-2.46a1.5 1.5 0 0 1 2.58 0l9.87 17.1A1.5 1.5 0 0 1 22.87 21H1.13a1.5 1.5 0 0 1-1.29-2.25l10.45-14.89Z'],
                            ['Users', 'admin.users.index', 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75'],
                            ['Posts', 'admin.posts.index', 'M4 4h16v16H4zM8 8h8M8 12h8M8 16h5'],
                            ['Comments', 'admin.comments.index', 'M21 15a4 4 0 0 1-4 4H7l-4 4V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z'],
                        ];
                    @endphp
                    @foreach ($items as [$label, $route, $path])
                        <a href="{{ route($route) }}" class="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition {{ request()->routeIs($route) ? 'bg-cyan-400 text-slate-950' : 'text-slate-300 hover:bg-white/10 hover:text-white' }}">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="{{ $path }}" /></svg>
                            {{ $label }}
                        </a>
                    @endforeach
                </nav>

                <div class="absolute bottom-6 w-60 rounded-xl border border-white/10 bg-white/5 p-4">
                    <div class="text-sm font-semibold">{{ auth()->user()->name }}</div>
                    <div class="mt-1 text-xs text-slate-400">{{ auth()->user()->email }}</div>
                    <form method="POST" action="{{ route('admin.logout') }}" class="mt-4">
                        @csrf
                        <button class="w-full rounded-lg bg-white/10 px-3 py-2 text-sm font-semibold text-white hover:bg-white/15">Sign out</button>
                    </form>
                </div>
            </aside>
        @endauth

        <main class="min-w-0 flex-1">
            @auth
                <header class="sticky top-0 z-10 border-b border-white/10 bg-slate-950/80 px-5 py-4 backdrop-blur lg:px-8">
                    <div class="flex items-center justify-between gap-4">
                        <div>
                            <p class="text-xs uppercase tracking-[0.25em] text-cyan-300">Admin</p>
                            <h1 class="mt-1 text-2xl font-bold">{{ $title ?? 'Dashboard' }}</h1>
                        </div>
                        <form method="POST" action="{{ route('admin.logout') }}" class="lg:hidden">
                            @csrf
                            <button class="rounded-lg bg-white/10 px-3 py-2 text-sm font-semibold">Sign out</button>
                        </form>
                    </div>
                </header>
            @endauth

            <div class="p-5 lg:p-8">
                @if (session('status'))
                    <div class="mb-5 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-100">{{ session('status') }}</div>
                @endif
                @if ($errors->any())
                    <div class="mb-5 rounded-lg border border-rose-400/30 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                        {{ $errors->first() }}
                    </div>
                @endif
                @yield('content')
            </div>
        </main>
    </div>
</body>
</html>
