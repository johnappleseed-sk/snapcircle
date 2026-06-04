import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsProvider>().fetchComments(
        widget.postId,
        refresh: true,
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _localError = 'Write a comment before sending.');
      return;
    }

    final commentsProvider = context.read<CommentsProvider>();
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
                child: _CommentsBody(
                  postId: widget.postId,
                  currentUserId: currentUserId,
                ),
              ),
            ),
            _CommentComposer(
              controller: _commentController,
              errorMessage: _localError,
              isSubmitting: commentsProvider.isSubmitting,
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

    if (commentsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (commentsProvider.errorMessage != null &&
        commentsProvider.comments.isEmpty) {
      return _ScrollableState(
        child: _CommentsErrorState(
          message: commentsProvider.errorMessage!,
          onRetry: () => commentsProvider.fetchComments(postId, refresh: true),
        ),
      );
    }

    if (commentsProvider.comments.isEmpty) {
      return const _ScrollableState(child: _EmptyCommentsState());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: commentsProvider.comments.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == commentsProvider.comments.length) {
          return _LoadMoreCommentsSection(postId: postId);
        }

        final comment = commentsProvider.comments[index];
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: commentsProvider.isLoadingMore
            ? null
            : () => commentsProvider.loadMoreComments(postId),
        child: commentsProvider.isLoadingMore
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

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final String? errorMessage;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _CommentComposer({
    required this.controller,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: isSubmitting ? null : onSubmit,
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
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}

class _CommentsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommentsErrorState({required this.message, required this.onRetry});

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

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.mutedText,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'No comments yet',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Start the conversation with the first comment.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
