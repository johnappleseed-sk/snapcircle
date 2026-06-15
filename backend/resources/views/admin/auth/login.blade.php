@extends('admin.layout', ['title' => 'Admin Login'])

@section('content')
    <div class="mx-auto flex min-h-[calc(100vh-4rem)] max-w-md items-center">
        <div class="w-full rounded-2xl border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/30">
            <div class="mb-8">
                <div class="inline-flex rounded-full bg-cyan-400/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.25em] text-cyan-300">SnapCircle</div>
                <h1 class="mt-4 text-3xl font-bold">Admin login</h1>
                <p class="mt-2 text-sm text-slate-400">Moderate reports, users, posts, and comments from the web dashboard.</p>
            </div>

            <form method="POST" action="{{ route('admin.authenticate') }}" class="space-y-5">
                @csrf
                <div>
                    <label for="email" class="text-sm font-medium text-slate-200">Email</label>
                    <input id="email" name="email" type="email" value="{{ old('email', 'admin@snapcircle.test') }}" required autofocus class="mt-2 w-full rounded-lg border border-white/10 bg-slate-900 px-4 py-3 text-sm text-white outline-none ring-cyan-400/40 placeholder:text-slate-500 focus:border-cyan-300 focus:ring-4">
                </div>
                <div>
                    <label for="password" class="text-sm font-medium text-slate-200">Password</label>
                    <input id="password" name="password" type="password" required class="mt-2 w-full rounded-lg border border-white/10 bg-slate-900 px-4 py-3 text-sm text-white outline-none ring-cyan-400/40 focus:border-cyan-300 focus:ring-4">
                    <p class="mt-2 text-xs text-slate-500">Seeded local password: <span class="font-mono text-slate-300">password</span></p>
                </div>
                <label class="flex items-center gap-2 text-sm text-slate-300">
                    <input type="checkbox" name="remember" value="1" class="rounded border-white/10 bg-slate-900 text-cyan-400">
                    Remember this browser
                </label>
                <button class="w-full rounded-lg bg-cyan-400 px-4 py-3 text-sm font-bold text-slate-950 transition hover:bg-cyan-300">Sign in</button>
            </form>
        </div>
    </div>
@endsection
