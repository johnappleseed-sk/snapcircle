import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
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
              return ErrorView(message: provider.errorMessage!, onRetry: _fetch);
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
      child: Row(
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('${user.role} • ${user.accountStatus}'),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = isBanned
                  ? await provider.unbanUser(user.id)
                  : await _confirmBan(context, user);
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
        ],
      ),
    );
  }

  Future<bool> _confirmBan(BuildContext context, UserModel user) async {
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

    if (confirmed != true || !context.mounted || reason.isEmpty) {
      return false;
    }

    return context.read<AdminProvider>().banUser(user.id, reason);
  }
}
