import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/realtime/realtime_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_skeleton_tile.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().refreshNotifications().then((_) {
        if (mounted) {
          final unreadCount = context.read<NotificationsProvider>().unreadCount;
          context.read<RealtimeProvider>().updateUnreadNotificationsCount(
            unreadCount,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: provider.unreadCount == 0
                ? null
                : () async {
                    await provider.markAllAsRead();
                    if (context.mounted) {
                      context
                          .read<RealtimeProvider>()
                          .updateUnreadNotificationsCount(0);
                    }
                  },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refreshNotifications();
          if (context.mounted) {
            context.read<RealtimeProvider>().updateUnreadNotificationsCount(
              provider.unreadCount,
            );
          }
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingXL,
          ),
          itemCount: _itemCount(provider),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _NotificationFilters(provider: provider);
            }

            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Column(
                children: [
                  NotificationSkeletonTile(),
                  SizedBox(height: AppSizes.paddingMedium),
                  NotificationSkeletonTile(),
                  SizedBox(height: AppSizes.paddingMedium),
                  NotificationSkeletonTile(),
                ],
              );
            }

            if (provider.errorMessage != null &&
                provider.notifications.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: provider.refreshNotifications,
              );
            }

            if (provider.notifications.isEmpty) {
              return const EmptyView(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                subtitle: 'Your SnapCircle updates will appear here.',
              );
            }

            final itemIndex = index - 1;
            if (itemIndex == provider.notifications.length) {
              if (!provider.hasMore) {
                return const SizedBox.shrink();
              }

              return AppButton(
                label: 'Load more',
                variant: AppButtonVariant.outline,
                isLoading: provider.isLoadingMore,
                onPressed: provider.isLoadingMore
                    ? null
                    : provider.loadMoreNotifications,
              );
            }

            final notification = provider.notifications[itemIndex];
            return NotificationTile(
              notification: notification,
              onTap: () => _openNotification(context, provider, notification),
              onDelete: () => provider.deleteNotification(notification.id),
            );
          },
        ),
      ),
    );
  }

  int _itemCount(NotificationsProvider provider) {
    if (provider.notifications.isEmpty) {
      return 2;
    }

    return provider.notifications.length + 2;
  }

  Future<void> _openNotification(
    BuildContext context,
    NotificationsProvider provider,
    NotificationModel notification,
  ) async {
    await provider.markAsRead(notification.id);
    if (!context.mounted) {
      return;
    }
    context.read<RealtimeProvider>().updateUnreadNotificationsCount(
      provider.unreadCount,
    );

    if (notification.postId != null) {
      context.push('/posts/${notification.postId}');
      return;
    }

    if (notification.type == 'follow_requested') {
      context.push('/follow-requests');
      return;
    }

    if ((notification.type == 'user_followed' ||
            notification.type == 'follow_request_approved') &&
        notification.actor != null) {
      context.push('/users/${notification.actor!.id}');
    }
  }
}

class _NotificationFilters extends StatelessWidget {
  final NotificationsProvider provider;

  const _NotificationFilters({required this.provider});

  static const _filters = [
    ('all', 'All'),
    ('unread', 'Unread'),
    ('read', 'Read'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSizes.paddingSmall),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return ChoiceChip(
            label: Text(filter.$2),
            selected: provider.currentFilter == filter.$1,
            onSelected: (_) => provider.changeFilter(filter.$1),
          );
        },
      ),
    );
  }
}
