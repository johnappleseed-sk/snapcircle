import 'package:go_router/go_router.dart';

import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/chat/models/conversation_model.dart';
import '../features/chat/screens/chat_detail_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/comments/screens/comments_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/feed/models/post_model.dart';
import '../features/feed/screens/home_screen.dart';
import '../features/feed/screens/post_detail_screen.dart';
import '../features/feed/screens/saved_posts_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../core/widgets/app_shell.dart';
import '../features/post/screens/create_post_screen.dart';
import '../features/post/screens/create_hub_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/follow_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/user_profile_screen.dart';
import '../features/settings/screens/account_settings_screen.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/settings/screens/privacy_settings_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/stories/models/story_model.dart';
import '../features/stories/screens/create_story_screen.dart';
import '../features/stories/screens/story_viewer_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
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
        final isOnboarding = location == onboarding;
        final isLogin = location == login;
        final isAdminRoute = location.startsWith('/admin');
        final userRole = authProvider.user?.role;
        final canAccessAdmin = userRole == 'admin' || userRole == 'moderator';

        if (isSplash || isOnboarding) {
          return null;
        }

        if (!authProvider.isAuthenticated && !isLogin) {
          return login;
        }

        if (authProvider.isAuthenticated && isLogin) {
          return home;
        }

        if (authProvider.isAuthenticated && isAdminRoute && !canAccessAdmin) {
          return home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: home,
          builder: (context, state) =>
              const AppShell(currentIndex: 0, child: HomeScreen()),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) =>
              const AppShell(currentIndex: 1, child: ExploreScreen()),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) =>
              const AppShell(currentIndex: 2, child: CreateHubScreen()),
        ),
        GoRoute(
          path: createPost,
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/posts/:postId/edit',
          builder: (context, state) {
            final postId = int.tryParse(state.pathParameters['postId'] ?? '');
            final post = state.extra is PostModel
                ? state.extra as PostModel
                : null;
            if (post == null) {
              return PostDetailScreen(postId: postId ?? 0);
            }
            return CreatePostScreen(initialPost: post);
          },
        ),
        GoRoute(
          path: '/posts/:postId',
          builder: (context, state) {
            final postId = int.tryParse(state.pathParameters['postId'] ?? '');
            final post = state.extra is PostModel
                ? state.extra as PostModel
                : null;

            return PostDetailScreen(postId: postId ?? 0, initialPost: post);
          },
        ),
        GoRoute(
          path: '/saved-posts',
          builder: (context, state) => const SavedPostsScreen(),
        ),
        GoRoute(
          path: '/stories/create',
          builder: (context, state) => const CreateStoryScreen(),
        ),
        GoRoute(
          path: '/stories/:storyId',
          builder: (context, state) {
            final storyId = int.tryParse(state.pathParameters['storyId'] ?? '');
            final story = state.extra is StoryModel
                ? state.extra as StoryModel
                : null;

            return StoryViewerScreen(
              storyId: storyId ?? 0,
              initialStory: story,
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              const AppShell(currentIndex: 3, child: NotificationsScreen()),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (context, state) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/account',
          builder: (context, state) => const AccountSettingsScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const AdminReportsScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: '/messages/:conversationId',
          builder: (context, state) {
            final conversationId = int.tryParse(
              state.pathParameters['conversationId'] ?? '',
            );
            final conversation = state.extra is ConversationModel
                ? state.extra as ConversationModel
                : null;

            return ChatDetailScreen(
              conversationId: conversationId ?? 0,
              initialConversation: conversation,
            );
          },
        ),
        GoRoute(
          path: '/posts/:postId/comments',
          builder: (context, state) {
            final postId = int.tryParse(state.pathParameters['postId'] ?? '');
            final post = state.extra is PostModel
                ? state.extra as PostModel
                : null;

            return CommentsScreen(postId: postId ?? 0, post: post);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const AppShell(currentIndex: 4, child: ProfileScreen()),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/users/:userId',
          builder: (context, state) {
            final userId = int.tryParse(state.pathParameters['userId'] ?? '');
            return UserProfileScreen(userId: userId ?? 0);
          },
        ),
        GoRoute(
          path: '/u/:username',
          builder: (context, state) {
            return UserProfileScreen(
              username: state.pathParameters['username'],
            );
          },
        ),
        GoRoute(
          path: '/users/:userId/followers',
          builder: (context, state) {
            final userId = int.tryParse(state.pathParameters['userId'] ?? '');
            return FollowListScreen(
              userId: userId ?? 0,
              type: FollowListType.followers,
              title: 'Followers',
            );
          },
        ),
        GoRoute(
          path: '/users/:userId/following',
          builder: (context, state) {
            final userId = int.tryParse(state.pathParameters['userId'] ?? '');
            return FollowListScreen(
              userId: userId ?? 0,
              type: FollowListType.following,
              title: 'Following',
            );
          },
        ),
        GoRoute(
          path: '/search',
          redirect: (context, state) => '/explore',
        ),
      ],
    );
  }
}
