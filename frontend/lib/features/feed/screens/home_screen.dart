import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/realtime/realtime_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../stories/providers/stories_provider.dart';
import '../../stories/widgets/stories_row.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/post_skeleton_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = context.read<FeedProvider>();
      if (feedProvider.posts.isEmpty) {
        feedProvider.fetchPosts(refresh: true);
      }
      context.read<StoriesProvider>().fetchStories(refresh: true);
      final notificationsProvider = context.read<NotificationsProvider>();
      final realtimeProvider = context.read<RealtimeProvider>();
      notificationsProvider.fetchUnreadCount().then((_) {
        if (mounted) {
          realtimeProvider.updateUnreadNotificationsCount(
            notificationsProvider.unreadCount,
          );
        }
      });
      realtimeProvider.startFeedStatusPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final realtimeProvider = context.watch<RealtimeProvider>();
    final unreadCount =
        realtimeProvider.unreadNotificationsCount >
            notificationsProvider.unreadCount
        ? realtimeProvider.unreadNotificationsCount
        : notificationsProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SnapCircle'),
            Text(
              'Share moments. Build your circle.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
          ),
          _NotificationIconButton(
            unreadCount: unreadCount,
            onPressed: () async {
              await context.push('/notifications');
              if (context.mounted) {
                final provider = context.read<NotificationsProvider>();
                await provider.fetchUnreadCount();
                if (context.mounted) {
                  context
                      .read<RealtimeProvider>()
                      .updateUnreadNotificationsCount(provider.unreadCount);
                }
              }
            },
          ),
          IconButton(
            onPressed: () => context.push('/saved-posts'),
            icon: const Icon(Icons.bookmark_border_outlined),
            tooltip: 'Saved posts',
          ),
          IconButton(
            onPressed: () async {
              await feedProvider.fetchPosts(refresh: true);
              if (context.mounted) {
                await context.read<StoriesProvider>().fetchStories(
                  refresh: true,
                );
              }
              if (context.mounted) {
                context.read<RealtimeProvider>().markFeedAsSeen();
                context.read<RealtimeProvider>().checkFeedStatus();
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh feed',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await feedProvider.fetchPosts(refresh: true);
          if (context.mounted) {
            await context.read<StoriesProvider>().fetchStories(refresh: true);
          }
          if (context.mounted) {
            context.read<RealtimeProvider>().markFeedAsSeen();
            context.read<RealtimeProvider>().checkFeedStatus();
          }
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 480) {
              feedProvider.loadMorePosts();
            }
            return false;
          },
          child: _FeedBody(
            feedProvider: feedProvider,
            showNewPostsBanner: realtimeProvider.hasNewPosts,
            currentUserId: authProvider.user?.id,
            onRefreshNewPosts: () async {
              await feedProvider.refreshPosts();
              if (context.mounted) {
                context.read<RealtimeProvider>().markFeedAsSeen();
                context.read<RealtimeProvider>().checkFeedStatus();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationIconButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
        child: const Icon(Icons.notifications_none_outlined),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  final FeedProvider feedProvider;
  final bool showNewPostsBanner;
  final int? currentUserId;
  final Future<void> Function() onRefreshNewPosts;

  const _FeedBody({
    required this.feedProvider,
    required this.showNewPostsBanner,
    required this.currentUserId,
    required this.onRefreshNewPosts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        96,
      ),
      itemCount: _itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              if (showNewPostsBanner) ...[
                _NewPostsBanner(onRefresh: onRefreshNewPosts),
                const SizedBox(height: AppSizes.paddingMedium),
              ],
              SectionHeader(
                title: 'Stories',
                actionLabel: 'Create',
                onAction: () => context.push('/stories/create'),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              const StoriesRow(),
              const SizedBox(height: AppSizes.paddingMedium),
              _FeedControls(
                selectedMode: feedProvider.currentMode,
                onModeChanged: feedProvider.changeMode,
              ),
            ],
          );
        }

        if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
          return const PostSkeletonCard();
        }

        if (feedProvider.errorMessage != null && feedProvider.posts.isEmpty) {
          return ErrorView(
            message: feedProvider.errorMessage!,
            onRetry: () => feedProvider.fetchPosts(refresh: true),
          );
        }

        if (feedProvider.posts.isEmpty) {
          return EmptyView(
            icon: _emptyIcon,
            title: _emptyTitle,
            subtitle: _emptySubtitle,
            actionLabel: feedProvider.currentMode == 'mine'
                ? 'Create post'
                : null,
            onAction: feedProvider.currentMode == 'mine'
                ? () => context.push('/create-post')
                : null,
          );
        }

        final postIndex = index - 1;

        if (postIndex == feedProvider.posts.length) {
          return _LoadMoreSection(feedProvider: feedProvider);
        }

        final post = feedProvider.posts[postIndex];
        return PostCard(
          post: post,
          canDelete:
              post.canDelete ||
              (currentUserId != null && post.user.id == currentUserId),
          onTap: () => context.push('/posts/${post.id}', extra: post),
          onCommentsTap: () {
            context.push('/posts/${post.id}/comments', extra: post);
          },
          onEdit: () => context.push('/posts/${post.id}/edit', extra: post),
          onDelete: () => _confirmDelete(context, post.id),
        );
      },
    );
  }

  int get _itemCount {
    if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
      return 5;
    }

    if (feedProvider.posts.isEmpty) {
      return 2;
    }

    return feedProvider.posts.length + 2;
  }

  IconData get _emptyIcon {
    return switch (feedProvider.currentMode) {
      'following' => Icons.people_outline,
      'popular' => Icons.trending_up,
      'mine' => Icons.person_outline,
      _ => Icons.dynamic_feed_outlined,
    };
  }

  String get _emptyTitle {
    return switch (feedProvider.currentMode) {
      'following' => 'No posts from people you follow.',
      'popular' => 'No popular posts yet.',
      'mine' => 'You have not posted yet.',
      _ => 'No posts yet.',
    };
  }

  String get _emptySubtitle {
    return switch (feedProvider.currentMode) {
      'following' => 'Find users to follow and build your circle.',
      'popular' => 'Like and comment on posts to make them trend.',
      'mine' => 'Share your first SnapCircle moment.',
      _ => 'Follow people or create your first post.',
    };
  }

  Future<void> _confirmDelete(BuildContext context, int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be removed from your feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final deleted = await context.read<FeedProvider>().deletePost(postId);
    if (!context.mounted) {
      return;
    }

    final message = deleted
        ? 'Post deleted.'
        : context.read<FeedProvider>().errorMessage ?? 'Unable to delete post.';

    if (deleted) {
      SnackbarHelper.showSuccess(context, message);
    } else {
      SnackbarHelper.showError(context, message);
    }
  }
}

class _NewPostsBanner extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NewPostsBanner({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingSmall,
        ),
        child: Row(
          children: [
            const Icon(Icons.dynamic_feed_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New posts available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedControls extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const _FeedControls({
    required this.selectedMode,
    required this.onModeChanged,
  });

  static const _modes = [
    ('all', 'For You'),
    ('following', 'Following'),
    ('popular', 'Popular'),
    ('mine', 'Mine'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Feed'),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _modes.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              final mode = _modes[index];
              return ChoiceChip(
                label: Text(mode.$2),
                selected: selectedMode == mode.$1,
                onSelected: (_) => onModeChanged(mode.$1),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadMoreSection extends StatelessWidget {
  final FeedProvider feedProvider;

  const _LoadMoreSection({required this.feedProvider});

  @override
  Widget build(BuildContext context) {
    if (!feedProvider.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'You are all caught up.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: AppButton(
        label: 'Load more',
        variant: AppButtonVariant.outline,
        onPressed: feedProvider.isLoadingMore
            ? null
            : feedProvider.loadMorePosts,
        isLoading: feedProvider.isLoadingMore,
      ),
    );
  }
}
