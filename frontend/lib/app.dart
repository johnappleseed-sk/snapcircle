import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/realtime/app_lifecycle_observer.dart';
import 'core/realtime/realtime_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/providers/conversations_provider.dart';
import 'features/chat/providers/messages_provider.dart';
import 'features/comments/providers/comments_provider.dart';
import 'features/feed/providers/feed_provider.dart';
import 'features/feed/providers/saved_posts_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/search/providers/users_provider.dart';
import 'features/stories/providers/stories_provider.dart';
import 'routes/app_router.dart';

class SnapCircleApp extends StatelessWidget {
  const SnapCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          FeedProvider,
          RealtimeProvider
        >(
          create: (_) => RealtimeProvider(),
          update: (_, authProvider, feedProvider, realtimeProvider) {
            final provider = realtimeProvider ?? RealtimeProvider();
            provider.updateFeedProvider(feedProvider);
            Future.microtask(() {
              if (authProvider.isAuthenticated) {
                provider.startFeedStatusPolling();
              } else {
                provider.clear();
              }
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => SavedPostsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => StoriesProvider()),
        ChangeNotifierProvider(create: (_) => CommentsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.read<AuthProvider>();

          return AppLifecycleObserver(
            child: MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              routerConfig: AppRouter.createRouter(authProvider),
            ),
          );
        },
      ),
    );
  }
}
