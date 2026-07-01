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
    final realtimeProvider = context.watch<RealtimeProvider>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.push('/create-post'),
          icon: const Icon(Icons.camera_alt_outlined),
          tooltip: 'Create post',
        ),
        title: const Text('SnapCircle'),
        actions: [
          IconButton(
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Messages',
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
    final horizontalPadding = screenWidth < 380 ? AppSizes.paddingSmall : 12.0;

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
              const StoriesRow(),
              const SizedBox(height: 14),
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
            sliver: SliverList.separated(
              itemCount: feedProvider.posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = feedProvider.posts[index];
                return PostCard(
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
