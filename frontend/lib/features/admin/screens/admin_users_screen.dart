import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/user_model.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchUsers(
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          itemCount: provider.users.isEmpty ? 2 : provider.users.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (index == 0) {
              return TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetch(),
                decoration: InputDecoration(
                  labelText: 'Search users',
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: IconButton(
                    onPressed: _fetch,
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Search',
                  ),
                ),
              );
            }

            if (provider.isLoading && provider.users.isEmpty) {
              return const SizedBox(
                height: 280,
                child: LoadingView(message: 'Loading users...'),
              );
            }

            if (provider.errorMessage != null && provider.users.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: _fetch,
              );
            }

            if (provider.users.isEmpty) {
              return const EmptyView(
                icon: Icons.people_outline,
                title: 'No users found',
                subtitle: 'Try another search term.',
              );
            }

            return _AdminUserTile(user: provider.users[index - 1]);
          },
        ),
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  final UserModel user;

  const _AdminUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    final isBanned = user.accountStatus == 'banned';

    return AppCard(
      onTap: () => context.push('/admin/users/${user.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                name: user.name,
                imageUrl: user.avatar,
                size: AppAvatarSize.medium,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSizes.paddingSmall,
                      runSpacing: AppSizes.paddingXS,
                      children: [
                        _AdminUserPill(label: user.role),
                        _AdminUserPill(label: user.accountStatus),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Update role',
                onSelected: (role) async {
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
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'user', child: Text('User')),
                  PopupMenuItem(value: 'moderator', child: Text('Moderator')),
                  PopupMenuItem(value: 'admin', child: Text('Admin')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () async {
                final bool success;
                if (isBanned) {
                  success = await provider.unbanUser(user.id);
                } else {
                  final reason = await _askBanReason(context, user);
                  if (!context.mounted || reason == null) return;
                  success = await provider.banUser(user.id, reason);
                }
                if (!context.mounted) return;
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
              },
              child: Text(isBanned ? 'Unban' : 'Ban'),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _askBanReason(BuildContext context, UserModel user) async {
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

class _AdminUserPill extends StatelessWidget {
  final String label;

  const _AdminUserPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
