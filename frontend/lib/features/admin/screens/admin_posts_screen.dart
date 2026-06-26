import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../feed/models/post_model.dart';
import '../providers/admin_provider.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchPosts();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<AdminProvider>().loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Moderation')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          itemCount: provider.posts.isEmpty ? 1 : provider.posts.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (provider.isLoading && provider.posts.isEmpty) {
              return const SizedBox(
                height: 320,
                child: LoadingView(message: 'Loading posts...'),
              );
            }

            if (provider.errorMessage != null && provider.posts.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: _fetch,
              );
            }

            if (provider.posts.isEmpty) {
              return const EmptyView(
                icon: Icons.dynamic_feed_outlined,
                title: 'No posts',
                subtitle: 'Posts that need moderation will appear here.',
              );
            }

            if (index == provider.posts.length) {
              if (provider.isLoadingMorePosts) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMedium,
                  ),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (provider.hasMorePosts) {
                return OutlinedButton.icon(
                  onPressed: provider.loadMorePosts,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more posts'),
                );
              }

              return Center(
                child: Text(
                  'End of post list',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return _AdminPostTile(post: provider.posts[index]);
          },
        ),
      ),
    );
  }
}

class _AdminPostTile extends StatelessWidget {
  final PostModel post;

  const _AdminPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final content = post.content?.trim();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: post.user.name,
                imageUrl: post.user.avatarUrl ?? post.user.avatar,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.name.isEmpty ? 'Unknown user' : post.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(DateFormatter.timeAgo(post.createdAt)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Post actions',
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Open post')),
                  PopupMenuItem(value: 'profile', child: Text('Open author')),
                  PopupMenuItem(value: 'delete', child: Text('Delete post')),
                ],
              ),
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            Text(content, maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Wrap(
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingSmall,
            children: [
              _MetricChip(
                icon: Icons.favorite_border,
                label: '${post.likesCount} likes',
              ),
              _MetricChip(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount} comments',
              ),
              _MetricChip(
                icon: Icons.bookmark_border,
                label: '${post.savesCount} saves',
              ),
              _MetricChip(
                icon: Icons.flag_outlined,
                label: '${post.reportsCount} reports',
              ),
              if (post.media.isNotEmpty)
                _MetricChip(
                  icon: Icons.image_outlined,
                  label: '${post.media.length} media',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    switch (value) {
      case 'open':
        context.push('/posts/${post.id}');
        return;
      case 'profile':
        context.push('/admin/users/${post.user.id}');
        return;
      case 'delete':
        final confirmed = await _confirmDelete(context);
        if (!context.mounted || confirmed != true) {
          return;
        }
        final provider = context.read<AdminProvider>();
        final success = await provider.deletePost(post.id);
        if (!context.mounted) {
          return;
        }
        if (success) {
          SnackbarHelper.showSuccess(context, 'Post deleted.');
        } else {
          SnackbarHelper.showError(
            context,
            provider.errorMessage ?? 'Unable to delete post.',
          );
        }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This removes the post and its media from SnapCircle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).dividerColor),
      backgroundColor: AppColors.surfaceMuted,
      visualDensity: VisualDensity.compact,
    );
  }
}
