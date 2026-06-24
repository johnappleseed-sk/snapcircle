import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/feed_repository.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final PostModel? initialPost;

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _feedRepository = FeedRepository();
  PostModel? _post;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_post != null) {
        context.read<FeedProvider>().upsertPost(_post!);
      }
      _fetchPost();
    });
  }

  Future<void> _fetchPost() async {
    setState(() {
      _isLoading = _post == null;
      _errorMessage = null;
    });

    try {
      final post = await _feedRepository.getPost(widget.postId);
      if (!mounted) {
        return;
      }

      context.read<FeedProvider>().upsertPost(post);
      setState(() {
        _post = post;
      });
    } on FeedException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load this post. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePost(BuildContext context, int postId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete post?',
      message: 'This post will be permanently removed from SnapCircle.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final deleted = await context.read<FeedProvider>().deletePost(postId);
    if (!context.mounted) {
      return;
    }

    if (deleted) {
      SnackbarHelper.showSuccess(context, 'Post deleted.');
      context.pop();
      return;
    }

    SnackbarHelper.showError(
      context,
      context.read<FeedProvider>().errorMessage ?? 'Unable to delete post.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final provider = context.watch<FeedProvider>();
    final post = _findProviderPost(provider) ?? _post;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      bottomNavigationBar: post == null
          ? null
          : _DetailActionBar(
              post: post,
              onCommentsTap: () {
                context.push('/posts/${post.id}/comments', extra: post);
              },
            ),
      body: RefreshIndicator(
        onRefresh: _fetchPost,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          children: [
            if (_isLoading && post == null)
              const SizedBox(
                height: 360,
                child: LoadingView(message: 'Loading post...'),
              )
            else if (_errorMessage != null && post == null)
              SizedBox(
                height: 360,
                child: ErrorView(message: _errorMessage!, onRetry: _fetchPost),
              )
            else if (post == null)
              const SizedBox(
                height: 360,
                child: EmptyView(
                  icon: Icons.article_outlined,
                  title: 'Post not found',
                  subtitle: 'This post may have been removed.',
                ),
              )
            else ...[
              PostCard(
                post: post,
                canDelete:
                    post.canDelete ||
                    (currentUserId != null && post.user.id == currentUserId),
                onCommentsTap: () {
                  context.push('/posts/${post.id}/comments', extra: post);
                },
                onEdit: () => context
                    .push('/posts/${post.id}/edit', extra: post)
                    .then((_) => _fetchPost()),
                onDelete: () => _deletePost(context, post.id),
                onBlockUser: post.isOwner
                    ? null
                    : () => _confirmBlockUser(context, post.user.id),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              const SizedBox(height: 72),
            ],
          ],
        ),
      ),
    );
  }

  PostModel? _findProviderPost(FeedProvider provider) {
    for (final post in provider.posts) {
      if (post.id == widget.postId) {
        return post;
      }
    }

    return null;
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
      SnackbarHelper.showSuccess(context, 'User blocked.');
      context.pop();
    } else {
      SnackbarHelper.showError(
        context,
        context.read<ProfileProvider>().errorMessage ??
            'Unable to block this user.',
      );
    }
  }
}

class _DetailActionBar extends StatelessWidget {
  final PostModel post;
  final VoidCallback onCommentsTap;

  const _DetailActionBar({required this.post, required this.onCommentsTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLikeUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isLikeUpdating(post.id),
    );
    final isSaveUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isSaveUpdating(post.id),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.34 : 0.12,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _TrayAction(
                icon: post.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                color: post.likedByMe ? AppColors.danger : null,
                isLoading: isLikeUpdating,
                onTap: isLikeUpdating
                    ? null
                    : () => context.read<FeedProvider>().toggleLike(post.id),
              ),
              _TrayAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
                onTap: onCommentsTap,
              ),
              _TrayAction(
                icon: post.savedByMe
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: '${post.savesCount}',
                color: post.savedByMe ? AppColors.primary : null,
                isLoading: isSaveUpdating,
                onTap: isSaveUpdating
                    ? null
                    : () => context.read<FeedProvider>().toggleSave(post.id),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.read<FeedProvider>().sharePost(post),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrayAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _TrayAction({
    required this.icon,
    required this.label,
    this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.72);
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 21),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }
}
