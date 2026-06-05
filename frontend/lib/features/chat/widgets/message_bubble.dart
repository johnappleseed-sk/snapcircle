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

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.card,
            border: isMine ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSizes.radiusMedium),
              topRight: const Radius.circular(AppSizes.radiusMedium),
              bottomLeft: Radius.circular(
                isMine ? AppSizes.radiusMedium : AppSizes.radiusSmall,
              ),
              bottomRight: Radius.circular(
                isMine ? AppSizes.radiusSmall : AppSizes.radiusMedium,
              ),
            ),
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
                    color: isMine ? Colors.white : AppColors.textPrimary,
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
