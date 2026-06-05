import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/saved_posts_provider.dart';
import '../widgets/post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SavedPostsProvider>();
      if (provider.posts.isEmpty) {
        provider.fetchSavedPosts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedPostsProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchSavedPosts(refresh: true),
        child: _SavedPostsBody(
          currentUserId: currentUserId,
          provider: provider,
        ),
      ),
    );
  }
}

class _SavedPostsBody extends StatelessWidget {
  final int? currentUserId;
  final SavedPostsProvider provider;

  const _SavedPostsBody({required this.currentUserId, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const LoadingView(message: 'Loading saved posts...');
    }

    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          const SizedBox(height: 96),
          ErrorView(
            message: provider.errorMessage!,
            onRetry: () => provider.fetchSavedPosts(refresh: true),
          ),
        ],
      );
    }

    if (provider.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: const [
          SizedBox(height: 96),
          EmptyView(
            icon: Icons.bookmark_border_outlined,
            title: 'No saved posts yet',
            subtitle: 'Save posts you want to revisit later.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingXL,
      ),
      itemCount: provider.posts.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingMedium),
      itemBuilder: (context, index) {
        if (index == provider.posts.length) {
          if (!provider.hasMore) {
            return const SizedBox.shrink();
          }

          return AppButton(
            label: 'Load more',
            variant: AppButtonVariant.outline,
            isLoading: provider.isLoadingMore,
            onPressed: provider.isLoadingMore
                ? null
                : provider.loadMoreSavedPosts,
          );
        }

        final post = provider.posts[index];
        return PostCard(
          post: post,
          canDelete:
              post.canDelete ||
              (currentUserId != null && post.user.id == currentUserId),
          onTap: () => context.push('/posts/${post.id}', extra: post),
          onCommentsTap: () {
            context.push('/posts/${post.id}/comments', extra: post);
          },
          onDelete: () async {
            final deleted = await context.read<FeedProvider>().deletePost(
              post.id,
            );
            if (deleted && context.mounted) {
              provider.removeSavedPost(post.id);
              SnackbarHelper.showSuccess(context, 'Post deleted.');
            }
          },
          onSaveTap: () async {
            final removed = await provider.unsavePost(post.id);
            if (context.mounted) {
              if (removed) {
                SnackbarHelper.showSuccess(
                  context,
                  'Post removed from saved posts.',
                );
              } else if (provider.errorMessage != null) {
                SnackbarHelper.showError(context, provider.errorMessage!);
              }
            }
            return removed;
          },
        );
      },
    );
  }
}
