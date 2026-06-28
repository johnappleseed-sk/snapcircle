import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/saved_posts_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/post_skeleton_card.dart';

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
      appBar: AppBar(
        title: const Text('Saved Posts'),
        actions: [
          IconButton(
            onPressed: () => context.push('/saved-collections'),
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'Saved collections',
          ),
        ],
      ),
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
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    if (provider.isLoading && provider.posts.isEmpty) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSizes.paddingMedium,
          horizontalPadding,
          AppSizes.paddingXL,
        ),
        itemCount: 3,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.paddingMedium),
        itemBuilder: (context, index) => const PostSkeletonCard(),
      );
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
            subtitle: 'Tap the bookmark on posts you want to revisit later.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSizes.paddingMedium,
        horizontalPadding,
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
          onEdit: () => context.push('/posts/${post.id}/edit', extra: post),
          onDelete: () async {
            final confirmed = await showConfirmationDialog(
              context: context,
              title: 'Delete post?',
              message: 'This saved post will be permanently removed.',
              confirmLabel: 'Delete',
              isDestructive: true,
            );
            if (!confirmed || !context.mounted) {
              return;
            }

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
          onBlockUser: post.isOwner
              ? null
              : () => _confirmBlockUser(context, post.user.id),
        );
      },
    );
  }

  Future<void> _confirmBlockUser(BuildContext context, int userId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Block this user?',
      message:
          'Their posts will be hidden and they will not be able to follow or message you.',
      confirmLabel: 'Block',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final blocked = await context.read<ProfileProvider>().blockUser(userId);
    if (!context.mounted) {
      return;
    }

    if (blocked) {
      context.read<FeedProvider>().removePostsByUser(userId);
      provider.posts
          .where((post) => post.user.id == userId)
          .map((post) => post.id)
          .toList()
          .forEach(provider.removeSavedPost);
      SnackbarHelper.showSuccess(context, 'User blocked.');
    } else {
      SnackbarHelper.showError(
        context,
        context.read<ProfileProvider>().errorMessage ??
            'Unable to block this user.',
      );
    }
  }
}
