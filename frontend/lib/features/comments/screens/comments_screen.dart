import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/providers/feed_provider.dart';
import '../providers/comments_provider.dart';
import '../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final PostModel? post;

  const CommentsScreen({super.key, required this.postId, this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  CommentsProvider? _commentsProvider;
  String? _localError;
  bool _canSubmitComment = false;
  DateTime? _lastLoadMoreAttempt;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_handleComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsProvider>().fetchComments(
        widget.postId,
        refresh: true,
      );
      context.read<CommentsProvider>().startCommentsStatusPolling(
        widget.postId,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commentsProvider = context.read<CommentsProvider>();
  }

  @override
  void dispose() {
    _commentsProvider?.stopCommentsStatusPolling();
    _commentController.removeListener(_handleComposerChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    final canSubmit = _commentController.text.trim().isNotEmpty;
    if (canSubmit == _canSubmitComment) {
      return;
    }

    setState(() => _canSubmitComment = canSubmit);
  }

  Future<void> _submitComment() async {
    final commentsProvider = context.read<CommentsProvider>();
    if (commentsProvider.isSubmitting) {
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _localError = 'Write a comment before sending.');
      return;
    }

    final created = await commentsProvider.createComment(
      widget.postId,
      comment,
    );

    if (!mounted) {
      return;
    }

    if (created) {
      _commentController.clear();
      context.read<FeedProvider>().incrementCommentCount(widget.postId);
      setState(() => _localError = null);
      return;
    }

    setState(() {
      _localError =
          commentsProvider.errorMessage ?? 'Unable to create comment.';
    });
  }

  void _maybeLoadMore(ScrollMetrics metrics) {
    if (!mounted || metrics.extentAfter > 520) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastLoadMoreAttempt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(milliseconds: 500)) {
      return;
    }

    _lastLoadMoreAttempt = now;
    final provider = context.read<CommentsProvider>();
    if (provider.hasMore && !provider.isLoadingMore) {
      provider.loadMoreComments(widget.postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsProvider = context.watch<CommentsProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Comments' : widget.post!.user.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => commentsProvider.fetchComments(
                  widget.postId,
                  refresh: true,
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification ||
                        notification is OverscrollNotification ||
                        notification is ScrollEndNotification) {
                      _maybeLoadMore(notification.metrics);
                    }
                    return false;
                  },
                  child: _CommentsBody(
                    postId: widget.postId,
                    currentUserId: currentUserId,
                  ),
                ),
              ),
            ),
            _CommentComposer(
              controller: _commentController,
              errorMessage: _localError,
              isSubmitting: commentsProvider.isSubmitting,
              canSubmit: _canSubmitComment,
              onSubmit: _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsBody extends StatelessWidget {
  final int postId;
  final int? currentUserId;

  const _CommentsBody({required this.postId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final commentsProvider = context.watch<CommentsProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    if (commentsProvider.isLoading) {
      return const LoadingView(message: 'Loading comments...');
    }

    if (commentsProvider.errorMessage != null &&
        commentsProvider.comments.isEmpty) {
      return _ScrollableState(
        child: ErrorView(
          message: commentsProvider.errorMessage!,
          onRetry: () => commentsProvider.fetchComments(postId, refresh: true),
        ),
      );
    }

    if (commentsProvider.comments.isEmpty) {
      return _ScrollableState(
        child: Column(
          children: [
            if (commentsProvider.hasNewComments) ...[
              _NewCommentsBanner(
                onRefresh: () async {
                  await commentsProvider.fetchComments(postId, refresh: true);
                  commentsProvider.markCommentsAsSeen();
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
            ],
            const EmptyView(
              icon: Icons.chat_bubble_outline,
              title: 'No comments yet',
              subtitle: 'Start the conversation with the first comment.',
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSizes.paddingMedium,
        horizontalPadding,
        AppSizes.paddingLarge,
      ),
      itemCount:
          commentsProvider.comments.length +
          1 +
          (commentsProvider.hasNewComments ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (commentsProvider.hasNewComments && index == 0) {
          return _NewCommentsBanner(
            onRefresh: () async {
              await commentsProvider.fetchComments(postId, refresh: true);
              commentsProvider.markCommentsAsSeen();
            },
          );
        }

        final offset = commentsProvider.hasNewComments ? 1 : 0;
        final commentIndex = index - offset;

        if (commentIndex == commentsProvider.comments.length) {
          return _LoadMoreCommentsSection(postId: postId);
        }

        final comment = commentsProvider.comments[commentIndex];
        return CommentTile(
          comment: comment,
          canManage: currentUserId != null && comment.user.id == currentUserId,
          onEdit: (updatedComment) {
            return context.read<CommentsProvider>().updateComment(
              comment.id,
              updatedComment,
            );
          },
          onDelete: () async {
            final deleted = await context
                .read<CommentsProvider>()
                .deleteComment(comment.id);
            if (deleted && context.mounted) {
              context.read<FeedProvider>().decrementCommentCount(postId);
            }
            return deleted;
          },
        );
      },
    );
  }
}

class _NewCommentsBanner extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NewCommentsBanner({required this.onRefresh});

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
            const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New comments available',
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

class _LoadMoreCommentsSection extends StatelessWidget {
  final int postId;

  const _LoadMoreCommentsSection({required this.postId});

  @override
  Widget build(BuildContext context) {
    final commentsProvider = context.watch<CommentsProvider>();

    if (!commentsProvider.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No more comments.',
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
        onPressed: commentsProvider.isLoadingMore
            ? null
            : () => commentsProvider.loadMoreComments(postId),
        isLoading: commentsProvider.isLoadingMore,
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final String? errorMessage;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const _CommentComposer({
    required this.controller,
    required this.errorMessage,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSizes.paddingSmall,
          horizontalPadding,
          AppSizes.paddingSmall + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      labelText: 'Comment',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                SizedBox.square(
                  dimension: 48,
                  child: IconButton.filled(
                    onPressed: isSubmitting || !canSubmit ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    tooltip: 'Send comment',
                  ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}
