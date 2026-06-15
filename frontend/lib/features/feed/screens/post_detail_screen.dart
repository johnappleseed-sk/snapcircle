import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
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
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AppButton(
                label: 'Open comments',
                icon: Icons.chat_bubble_outline,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  context.push('/posts/${post.id}/comments', extra: post);
                },
              ),
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
}
