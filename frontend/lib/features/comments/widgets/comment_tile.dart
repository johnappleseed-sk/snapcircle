import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../reports/widgets/report_dialog.dart';
import '../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool canManage;
  final Future<bool> Function(String comment)? onEdit;
  final Future<bool> Function()? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          name: comment.user.name,
          imageUrl: comment.user.avatar,
          size: AppAvatarSize.small,
        ),
        SizedBox(
          width: isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
        ),
        Expanded(
          child: AppCard(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 14,
              12,
              isCompact ? 12 : 14,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.user.name.isEmpty
                                ? 'SnapCircle User'
                                : comment.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.timeAgo(comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                    if (canManage || !comment.user.isMe)
                      PopupMenuButton<String>(
                        tooltip: 'Comment options',
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(context);
                          }
                          if (value == 'delete') {
                            _confirmDelete(context);
                          }
                          if (value == 'report') {
                            ReportDialog.show(
                              context,
                              targetType: ReportTargetType.comment,
                              targetId: comment.id,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (canManage)
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
                          if (canManage)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          if (!comment.user.isMe)
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
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  comment.comment,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: comment.comment);
    final updatedComment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Update your comment...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updatedComment == null || updatedComment.isEmpty || !context.mounted) {
      return;
    }

    final success = await onEdit?.call(updatedComment) ?? false;
    if (!context.mounted) {
      return;
    }

    if (success) {
      SnackbarHelper.showSuccess(context, 'Comment updated.');
    } else {
      SnackbarHelper.showError(context, 'Unable to update comment.');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete comment?',
      message: 'This comment will be removed from the post.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final success = await onDelete?.call() ?? false;
    if (!context.mounted) {
      return;
    }

    if (success) {
      SnackbarHelper.showSuccess(context, 'Comment deleted.');
    } else {
      SnackbarHelper.showError(context, 'Unable to delete comment.');
    }
  }
}
