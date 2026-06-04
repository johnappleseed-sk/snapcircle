import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    _FeedTab(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/create-post'),
              tooltip: 'Create post',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex == 2 ? 3 : _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/create-post');
            return;
          }

          final mappedIndex = index > 2 ? index - 1 : index;
          setState(() => _currentIndex = mappedIndex);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = context.read<FeedProvider>();
      if (feedProvider.posts.isEmpty) {
        feedProvider.fetchPosts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapCircle'),
        actions: [
          IconButton(
            onPressed: () => feedProvider.fetchPosts(refresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh feed',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => feedProvider.fetchPosts(refresh: true),
        child: _FeedBody(
          feedProvider: feedProvider,
          currentUserId: authProvider.user?.id,
        ),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  final FeedProvider feedProvider;
  final int? currentUserId;

  const _FeedBody({required this.feedProvider, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (feedProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedProvider.errorMessage != null && feedProvider.posts.isEmpty) {
      return _ScrollableState(
        child: _FeedErrorState(
          message: feedProvider.errorMessage!,
          onRetry: () => feedProvider.fetchPosts(refresh: true),
        ),
      );
    }

    if (feedProvider.posts.isEmpty) {
      return const _ScrollableState(child: _EmptyFeedState());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: feedProvider.posts.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == feedProvider.posts.length) {
          return _LoadMoreSection(feedProvider: feedProvider);
        }

        final post = feedProvider.posts[index];
        return PostCard(
          post: post,
          canDelete: currentUserId != null && post.user.id == currentUserId,
          onCommentsTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comments will be added in the next step.'),
              ),
            );
          },
          onDelete: () => _confirmDelete(context, post.id),
        );
      },
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Post deleted.'
              : context.read<FeedProvider>().errorMessage ??
                    'Unable to delete post.',
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: feedProvider.isLoadingMore
            ? null
            : feedProvider.loadMorePosts,
        child: feedProvider.isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Load more'),
      ),
    );
  }
}

class _ScrollableState extends StatelessWidget {
  final Widget child;

  const _ScrollableState({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FeedErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.dynamic_feed_outlined,
          color: AppColors.mutedText,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'No posts yet',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Create the first SnapCircle post to start the feed.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
