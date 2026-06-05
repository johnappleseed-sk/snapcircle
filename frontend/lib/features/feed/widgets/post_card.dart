import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onTap;
  final Future<bool> Function()? onSaveTap;
  final VoidCallback? onShareTap;

  const PostCard({
    super.key,
    required this.post,
    this.canDelete = false,
    this.onDelete,
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

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: post.user.name,
                imageUrl: post.user.avatar,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      DateFormatter.timeAgo(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Post options',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete'),
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
                height: 1.35,
                color: AppColors.text,
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
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.background,
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
          Wrap(
            spacing: AppSizes.paddingLarge,
            runSpacing: AppSizes.paddingSmall,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: isLikeUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _PostMetric(
                          icon: post.likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          label: post.likesCount.toString(),
                          color: post.likedByMe
                              ? AppColors.danger
                              : AppColors.mutedText,
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingLarge),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onCommentsTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _PostMetric(
                    icon: Icons.chat_bubble_outline,
                    label: post.commentsCount.toString(),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: isSaveUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _PostMetric(
                          icon: post.savedByMe
                              ? Icons.bookmark
                              : Icons.bookmark_border_outlined,
                          label: post.savesCount.toString(),
                          color: post.savedByMe
                              ? AppColors.primary
                              : AppColors.mutedText,
                        ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap:
                    onShareTap ??
                    () => context.read<FeedProvider>().sharePost(post),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: _PostMetric(
                    icon: Icons.ios_share_outlined,
                    label: 'Share',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PostMetric({
    required this.icon,
    required this.label,
    this.color = AppColors.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
