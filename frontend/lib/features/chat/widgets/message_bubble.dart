import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final theme = Theme.of(context);
    final otherBubble = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72)
        : theme.colorScheme.surface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMine ? theme.colorScheme.primary : otherBubble,
            border: isMine ? null : Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSizes.radiusSmall),
              topRight: const Radius.circular(AppSizes.radiusSmall),
              bottomLeft: Radius.circular(isMine ? AppSizes.radiusSmall : 3),
              bottomRight: Radius.circular(isMine ? 3 : AppSizes.radiusSmall),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.035,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMine ? Colors.white : theme.colorScheme.onSurface,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormatter.timeAgo(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.78)
                            : AppColors.mutedText,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
