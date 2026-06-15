import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final actor = notification.actor;
    final preview = _previewText;
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppCard(
      color: notification.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.08),
      onTap: onTap,
      padding: EdgeInsets.all(isCompact ? 12 : AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            name: actor?.name ?? 'SnapCircle',
            imageUrl: actor?.avatar,
            size: AppAvatarSize.medium,
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!notification.isRead) ...[
                      Container(
                        height: 9,
                        width: 9,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                    ],
                    Expanded(
                      child: Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingXS),
                    PopupMenuButton<String>(
                      tooltip: 'Notification options',
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
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              SizedBox(width: AppSizes.paddingSmall),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingXS),
                Text(
                  DateFormatter.timeAgo(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (preview != null) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingSmall),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? get _previewText {
    final commentPreview = notification.data?['comment_preview']?.toString();
    if (commentPreview != null && commentPreview.isNotEmpty) {
      return commentPreview;
    }

    final postPreview = notification.data?['post_preview']?.toString();
    if (postPreview != null && postPreview.isNotEmpty) {
      return postPreview;
    }

    return null;
  }
}
