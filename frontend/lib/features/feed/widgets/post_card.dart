import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = post.content != null && post.content!.trim().isNotEmpty;
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final feedProvider = context.watch<FeedProvider>();
    final isLikeUpdating = feedProvider.isLikeUpdating(post.id);
    final isSaveUpdating = feedProvider.isSaveUpdating(post.id);
    final username = post.user.username?.trim();
    final subtitle = [
      if (username != null && username.isNotEmpty) '@$username',
      DateFormatter.timeAgo(post.createdAt),
    ].join(' - ');
    final imageFill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final mediaCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            Text(
              post.content!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ],
          if (hasImage) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: mediaCacheWidth,
                  placeholder: (context, url) => Container(
                    color: imageFill,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: imageFill,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ),
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
                semanticLabel: 'Open comments',
                onTap: onCommentsTap,
              ),
              _PostAction(
                icon: Icons.ios_share_outlined,
                label: 'Share',
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
  final String semanticLabel;
  final FutureOr<void> Function()? onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.color,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                        key: ValueKey('${widget.icon}-${widget.label}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 22, color: foreground),
                          const SizedBox(width: 5),
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
