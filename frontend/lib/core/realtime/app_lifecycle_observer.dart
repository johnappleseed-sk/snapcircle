import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'realtime_provider.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  AuthProvider? authProvider;
  RealtimeProvider? realtimeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = context.read<AuthProvider>();
    realtimeProvider = context.read<RealtimeProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = authProvider;
    final realtime = realtimeProvider;
    if (auth == null || realtime == null) {
      return;
    }

    if (state == AppLifecycleState.resumed && auth.isAuthenticated) {
      realtime.startFeedStatusPolling();
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      realtime.stopFeedStatusPolling();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
