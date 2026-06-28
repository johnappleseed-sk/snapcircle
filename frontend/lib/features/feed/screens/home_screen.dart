import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/realtime/realtime_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_masonry_grid.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_header.dart';
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
  DateTime? _lastLoadMoreAttempt;

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

  void _maybeLoadMore(ScrollMetrics metrics) {
    if (!mounted || metrics.extentAfter > 720) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastLoadMoreAttempt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(milliseconds: 450)) {
      return;
    }

    _lastLoadMoreAttempt = now;
    context.read<FeedProvider>().loadMorePosts();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final realtimeProvider = context.watch<RealtimeProvider>();
    final unreadCount =
        realtimeProvider.unreadNotificationsCount >
            notificationsProvider.unreadCount
        ? realtimeProvider.unreadNotificationsCount
        : notificationsProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.paddingMedium,
        title: Builder(
          builder: (context) {
            final showSubtitle = MediaQuery.sizeOf(context).width >= 380;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SnapCircle'),
                if (showSubtitle)
                  Text(
                    'Share moments. Build your circle.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            );
          },
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
          _HomeOverflowMenu(
            onSavedPosts: () => context.push('/saved-posts'),
            onRefresh: () =>
                _refreshHome(context, feedProvider, realtimeProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHome(context, feedProvider, realtimeProvider),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification ||
                notification is OverscrollNotification ||
                notification is ScrollEndNotification) {
              _maybeLoadMore(notification.metrics);
            }
            return false;
          },
          child: _FeedBody(
            feedProvider: feedProvider,
            showNewPostsBanner: realtimeProvider.hasNewPosts,
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

  Future<void> _refreshHome(
    BuildContext context,
    FeedProvider feedProvider,
    RealtimeProvider realtimeProvider,
  ) async {
    await feedProvider.fetchPosts(refresh: true);
    if (context.mounted) {
      await context.read<StoriesProvider>().fetchStories(refresh: true);
    }
    if (context.mounted) {
      realtimeProvider.markFeedAsSeen();
      realtimeProvider.checkFeedStatus();
    }
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

class _HomeOverflowMenu extends StatelessWidget {
  final VoidCallback onSavedPosts;
  final Future<void> Function() onRefresh;

  const _HomeOverflowMenu({
    required this.onSavedPosts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HomeMenuAction>(
      tooltip: 'More feed actions',
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) {
        switch (action) {
          case _HomeMenuAction.saved:
            onSavedPosts();
          case _HomeMenuAction.refresh:
            onRefresh();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _HomeMenuAction.saved,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.bookmark_border_outlined),
            title: Text('Saved posts'),
          ),
        ),
        PopupMenuItem(
          value: _HomeMenuAction.refresh,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.refresh),
            title: Text('Refresh feed'),
          ),
        ),
      ],
    );
  }
}

enum _HomeMenuAction { saved, refresh }

class _FeedBody extends StatelessWidget {
  final FeedProvider feedProvider;
  final bool showNewPostsBanner;
  final Future<void> Function() onRefreshNewPosts;

  const _FeedBody({
    required this.feedProvider,
    required this.showNewPostsBanner,
    required this.onRefreshNewPosts,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return CustomScrollView(
      key: const PageStorageKey('home-feed-list'),
      cacheExtent: 1000,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            feedProvider.posts.isEmpty ? 96 : 0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              if (showNewPostsBanner) ...[
                _NewPostsBanner(onRefresh: onRefreshNewPosts),
                const SizedBox(height: AppSizes.paddingMedium),
              ],
              _HomeHero(
                onSearchTap: () => context.go('/explore'),
                onSavedTap: () => context.push('/saved-posts'),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
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
              const SizedBox(height: AppSizes.paddingMedium),
              if (feedProvider.isLoading && feedProvider.posts.isEmpty)
                const _WaterfallSkeleton()
              else if (feedProvider.errorMessage != null &&
                  feedProvider.posts.isEmpty)
                ErrorView(
                  message: feedProvider.errorMessage!,
                  onRetry: () => feedProvider.fetchPosts(refresh: true),
                )
              else if (feedProvider.posts.isEmpty)
                EmptyView(
                  icon: _emptyIcon,
                  title: _emptyTitle,
                  subtitle: _emptySubtitle,
                  actionLabel: feedProvider.currentMode == 'mine'
                      ? 'Create post'
                      : null,
                  onAction: feedProvider.currentMode == 'mine'
                      ? () => context.push('/create-post')
                      : null,
                )
              else
                const SizedBox.shrink(),
            ]),
          ),
        ),
        if (feedProvider.posts.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: AppLazyMasonryGrid(
              itemCount: feedProvider.posts.length,
              itemBuilder: (context, index) {
                final post = feedProvider.posts[index];
                return PostWaterfallCard(
                  post: post,
                  onTap: () => context.push('/posts/${post.id}', extra: post),
                  onCommentsTap: () {
                    context.push('/posts/${post.id}/comments', extra: post);
                  },
                );
              },
            ),
          ),
        if (feedProvider.posts.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSizes.paddingSmall,
              horizontalPadding,
              96,
            ),
            sliver: SliverToBoxAdapter(
              child: _LoadMoreSection(feedProvider: feedProvider),
            ),
          ),
      ],
    );
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
      _ => 'Your feed is quiet right now.',
    };
  }

  String get _emptySubtitle {
    return switch (feedProvider.currentMode) {
      'following' => 'Find users to follow and build your circle.',
      'popular' => 'Like and comment on posts to make them trend.',
      'mine' => 'Share your first SnapCircle moment.',
      _ => 'Explore people to follow or share your first SnapCircle moment.',
    };
  }
}

class _HomeHero extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onSavedTap;

  const _HomeHero({required this.onSearchTap, required this.onSavedTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.035,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.62,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search notes, creators, topics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.58,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: onSavedTap,
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Saved posts',
          ),
        ],
      ),
    );
  }
}

class _WaterfallSkeleton extends StatelessWidget {
  const _WaterfallSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppMasonryGrid(itemCount: 6, itemBuilder: _buildItem);
  }

  static Widget _buildItem(BuildContext context, int index) {
    return PostSkeletonCard(compact: true);
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
    ('all', 'For You', Icons.auto_awesome_outlined),
    ('following', 'Following', Icons.people_outline),
    ('popular', 'Popular', Icons.trending_up),
    ('mine', 'Mine', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Feed'),
        const SizedBox(height: AppSizes.paddingSmall),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final mode in _modes)
                ButtonSegment(
                  value: mode.$1,
                  icon: Icon(mode.$3, size: 18),
                  label: Text(mode.$2),
                ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (values) => onModeChanged(values.first),
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
