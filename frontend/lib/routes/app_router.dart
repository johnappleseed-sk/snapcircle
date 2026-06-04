import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/feed/screens/home_screen.dart';
import '../features/post/screens/create_post_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/search/screens/search_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String createPost = '/create-post';

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.uri.path;
        final isSplash = location == splash;
        final isLogin = location == login;

        if (isSplash) {
          return null;
        }

        if (!authProvider.isAuthenticated && !isLogin) {
          return login;
        }

        if (authProvider.isAuthenticated && isLogin) {
          return home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(path: home, builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: createPost,
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
      ],
    );
  }
}
