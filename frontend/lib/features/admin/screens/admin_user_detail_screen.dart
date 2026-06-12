import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/user_model.dart';
import '../providers/admin_provider.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final user = provider.selectedUser?.id == widget.userId
        ? provider.selectedUser
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('User Detail')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          children: [
            if (provider.isLoading && user == null)
              const SizedBox(
                height: 320,
                child: LoadingView(message: 'Loading user...'),
              )
            else if (provider.errorMessage != null && user == null)
              ErrorView(message: provider.errorMessage!, onRetry: _fetch)
            else if (user != null) ...[
              _UserHeader(user: user),
              const SizedBox(height: AppSizes.paddingMedium),
              _UserStats(user: user),
              const SizedBox(height: AppSizes.paddingMedium),
              _UserActions(user: user),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final UserModel user;

  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppAvatar(
            name: user.name,
            imageUrl: user.avatarUrl ?? user.avatar,
            size: AppAvatarSize.large,
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (user.username != null) Text('@${user.username}'),
                Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSizes.paddingSmall),
                Wrap(
                  spacing: AppSizes.paddingSmall,
                  children: [
                    Chip(label: Text(user.role)),
                    Chip(label: Text(user.accountStatus)),
                    if (user.isPrivate) const Chip(label: Text('private')),
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

class _UserStats extends StatelessWidget {
  final UserModel user;

  const _UserStats({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _StatRow(label: 'Posts', value: user.postsCount.toString()),
          _StatRow(label: 'Followers', value: user.followersCount.toString()),
          _StatRow(label: 'Following', value: user.followingCount.toString()),
          _StatRow(label: 'Reports', value: user.reportsCount.toString()),
          _StatRow(label: 'Joined', value: DateFormatter.timeAgo(user.joinedAt)),
          if (user.bannedAt != null)
            _StatRow(
              label: 'Banned',
              value: DateFormatter.timeAgo(user.bannedAt),
            ),
          if (user.banReason != null)
            _StatRow(label: 'Ban reason', value: user.banReason!),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  final UserModel user;

  const _UserActions({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isBanned = user.accountStatus == 'banned';

    return Column(
      children: [
        AppButton(
          label: 'Open Public Profile',
          icon: Icons.person_outline,
          variant: AppButtonVariant.outline,
          onPressed: () => context.push('/users/${user.id}'),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        DropdownButtonFormField<String>(
          initialValue: user.role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: 'user', child: Text('User')),
            DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: provider.isLoading
              ? null
              : (role) async {
                  if (role == null || role == user.role) {
                    return;
                  }
                  final success = await provider.updateUserRole(user.id, role);
                  if (!context.mounted) return;
                  if (success) {
                    SnackbarHelper.showSuccess(context, 'User role updated.');
                  } else {
                    SnackbarHelper.showError(
                      context,
                      provider.errorMessage ?? 'Unable to update role.',
                    );
                  }
                },
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        AppButton(
          label: isBanned ? 'Unban User' : 'Ban User',
          icon: isBanned ? Icons.check_circle_outline : Icons.block,
          variant: isBanned
              ? AppButtonVariant.secondary
              : AppButtonVariant.danger,
          isLoading: provider.isLoading,
          onPressed: () => _toggleBan(context, provider, isBanned),
        ),
      ],
    );
  }

  Future<void> _toggleBan(
    BuildContext context,
    AdminProvider provider,
    bool isBanned,
  ) async {
    final bool success;
    if (isBanned) {
      success = await provider.unbanUser(user.id);
    } else {
      final reason = await _askBanReason(context);
      if (!context.mounted || reason == null) {
        return;
      }
      success = await provider.banUser(user.id, reason);
    }

    if (!context.mounted) {
      return;
    }
    if (success) {
      SnackbarHelper.showSuccess(
        context,
        isBanned ? 'User unbanned.' : 'User banned.',
      );
    } else {
      SnackbarHelper.showError(
        context,
        provider.errorMessage ?? 'Unable to update user.',
      );
    }
  }

  Future<String?> _askBanReason(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Violation of community guidelines',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ban ${user.name}?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();

    if (confirmed != true || reason.isEmpty) {
      return null;
    }

    return reason;
  }
}
