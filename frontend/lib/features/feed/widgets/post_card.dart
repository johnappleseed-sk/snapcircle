import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../reports/widgets/report_dialog.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import 'hashtag_caption.dart';
import 'post_media_carousel.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onTap;
  final Future<bool> Function()? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBlockUser;
  final ValueChanged<String>? onTagTap;

  const PostCard({
    super.key,
    required this.post,
    this.canDelete = false,
    this.onDelete,
    this.onEdit,
    this.onCommentsTap,
    this.onTap,
    this.onSaveTap,
    this.onShareTap,
    this.onBlockUser,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = post.content != null && post.content!.trim().isNotEmpty;
    final hasMedia = post.media.isNotEmpty;
    final isLikeUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isLikeUpdating(post.id),
    );
    final isSaveUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isSaveUpdating(post.id),
    );
    final username = post.user.username?.trim();
    final subtitle = [
      if (username != null && username.isNotEmpty) '@$username',
      DateFormatter.timeAgo(post.createdAt),
    ].join(' - ');
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 14,
        14,
        isCompact ? 12 : 14,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: post.user.name,
                imageUrl: post.user.avatarUrl ?? post.user.avatar,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.name.isEmpty
                          ? 'SnapCircle User'
                          : post.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete || post.canUpdate || !post.isOwner)
                IconButton(
                  onPressed: () => _showPostActions(context),
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Post options',
                ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            HashtagCaption(
              text: post.content!,
              onTagTap: onTagTap ?? (tag) => _openTag(context, tag),
            ),
          ],
          if (hasMedia) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            PostMediaCarousel(media: post.media),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              _PostAction(
                icon: post.likedByMe
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                label: post.likesCount.toString(),
                color: post.likedByMe ? AppColors.danger : null,
                isLoading: isLikeUpdating,
                compact: isCompact,
                semanticLabel: post.likedByMe ? 'Unlike post' : 'Like post',
                onTap: isLikeUpdating
                    ? null
                    : () async {
                        final success = await context
                            .read<FeedProvider>()
                            .toggleLike(post.id);
                        if (!success && context.mounted) {
                          final message = context
                              .read<FeedProvider>()
                              .errorMessage;
                          if (message != null) {
                            SnackbarHelper.showError(context, message);
                          }
                        }
                      },
              ),
              _PostAction(
                icon: Icons.chat_bubble_outline,
                label: post.commentsCount.toString(),
                compact: isCompact,
                semanticLabel: 'Open comments',
                onTap: onCommentsTap,
              ),
              _PostAction(
                icon: Icons.ios_share_outlined,
                label: 'Share',
                compact: isCompact,
                semanticLabel: 'Share post',
                onTap:
                    onShareTap ??
                    () => context.read<FeedProvider>().sharePost(post),
              ),
              const Spacer(),
              _PostAction(
                icon: post.savedByMe
                    ? Icons.bookmark
                    : Icons.bookmark_border_outlined,
                label: post.savesCount.toString(),
                color: post.savedByMe ? AppColors.primary : null,
                isLoading: isSaveUpdating,
                compact: isCompact,
                semanticLabel: post.savedByMe ? 'Unsave post' : 'Save post',
                onTap: isSaveUpdating
                    ? null
                    : () async {
                        final success =
                            await (onSaveTap?.call() ??
                                context.read<FeedProvider>().toggleSave(
                                  post.id,
                                ));
                        if (!success && context.mounted) {
                          final message = context
                              .read<FeedProvider>()
                              .errorMessage;
                          if (message != null) {
                            SnackbarHelper.showError(context, message);
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTag(BuildContext context, String tag) {
    context.go('/explore/tags/${Uri.encodeComponent(tag)}');
  }

  Future<void> _showPostActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.canUpdate)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit post'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onEdit?.call();
                    },
                  ),
                if (canDelete)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    title: const Text('Delete post'),
                    textColor: AppColors.danger,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDelete?.call();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('View profile'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/users/${post.user.id}');
                  },
                ),
                if (post.content != null && post.content!.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy post text'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await Clipboard.setData(
                        ClipboardData(text: post.content!.trim()),
                      );
                      if (context.mounted) {
                        SnackbarHelper.showSuccess(
                          context,
                          'Post text copied.',
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: Icon(
                    post.savedByMe
                        ? Icons.bookmark_remove_outlined
                        : Icons.bookmark_add_outlined,
                  ),
                  title: Text(post.savedByMe ? 'Unsave post' : 'Save post'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final success =
                        await (onSaveTap?.call() ??
                            context.read<FeedProvider>().toggleSave(post.id));
                    if (!context.mounted) {
                      return;
                    }
                    if (success) {
                      SnackbarHelper.showSuccess(
                        context,
                        post.savedByMe ? 'Post unsaved.' : 'Post saved.',
                      );
                    } else {
                      final message = context
                          .read<FeedProvider>()
                          .errorMessage;
                      if (message != null) {
                        SnackbarHelper.showError(context, message);
                      }
                    }
                  },
                ),
                if (!post.isOwner && onBlockUser != null)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report post'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ReportDialog.show(
                        context,
                        targetType: ReportTargetType.post,
                        targetId: post.id,
                      );
                    },
                  ),
                if (!post.isOwner)
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Block user'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onBlockUser?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final bool compact;
  final String semanticLabel;
  final FutureOr<void> Function()? onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.color,
    this.compact = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_PostAction> createState() => _PostActionState();
}

class _PostActionState extends State<_PostAction> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null || widget.isLoading) {
      return;
    }

    setState(() => _isPressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _isPressed = false);
    }
    await onTap();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.color ?? AppColors.mutedText;
    final visibleLabel = widget.compact && widget.label.length > 3
        ? ''
        : widget.label;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        child: AnimatedScale(
          scale: _isPressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            onTap: widget.isLoading || widget.onTap == null ? null : _handleTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 4 : 6,
                  vertical: 6,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          key: ValueKey('${widget.icon}-$visibleLabel'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, size: 22, color: foreground),
                            if (visibleLabel.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Text(
                                visibleLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
