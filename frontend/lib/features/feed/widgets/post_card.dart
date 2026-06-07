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
    ].join(' · ');
    final imageFill = Theme.of(context).colorScheme.surfaceContainerHighest;

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
                PopupMenuButton<String>(
                  tooltip: 'Post options',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete?.call();
                    }
                    if (value == 'edit') {
                      onEdit?.call();
                    }
                    if (value == 'report') {
                      ReportDialog.show(
                        context,
                        targetType: ReportTargetType.post,
                        targetId: post.id,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (post.canUpdate)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    if (!post.isOwner)
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined),
                            SizedBox(width: 8),
                            Text('Report'),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              post.content!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
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
                onTap: onCommentsTap,
              ),
              _PostAction(
                icon: Icons.ios_share_outlined,
                label: 'Share',
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
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.mutedText;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
