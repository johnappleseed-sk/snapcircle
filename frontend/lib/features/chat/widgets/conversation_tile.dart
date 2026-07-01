import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final int? currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final participant = conversation.otherParticipant(currentUserId);
    final latestMessage = conversation.latestMessage?.message;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppAvatar(
            name: participant?.name ?? 'User',
            imageUrl: participant?.avatar,
            size: AppAvatarSize.medium,
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        participant?.name ?? 'Unknown user',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                      ),
                    ),
                    Text(
                      DateFormatter.timeAgo(
                        conversation.latestMessage?.createdAt ??
                            conversation.updatedAt,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        latestMessage == null || latestMessage.trim().isEmpty
                            ? 'No messages yet'
                            : latestMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: conversation.unreadCount > 0
                              ? textColor
                              : AppColors.textSecondary,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (conversation.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      _UnreadBadge(count: conversation.unreadCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
