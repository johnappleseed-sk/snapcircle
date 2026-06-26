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
  final _scrollController = ScrollController();
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchUsers(
      search: _searchController.text,
      role: _roleFilter,
      accountStatus: _statusFilter,
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<AdminProvider>().loadMoreUsers();
    }
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
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          itemCount: provider.users.isEmpty ? 2 : provider.users.length + 2,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AdminUserFilters(
                searchController: _searchController,
                role: _roleFilter,
                accountStatus: _statusFilter,
                onRoleChanged: (value) {
                  setState(() => _roleFilter = value);
                  _fetch();
                },
                onStatusChanged: (value) {
                  setState(() => _statusFilter = value);
                  _fetch();
                },
                onSearch: _fetch,
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _roleFilter = 'all';
                    _statusFilter = 'all';
                  });
                  _fetch();
                },
              );
            }

            if (provider.users.isNotEmpty &&
                index == provider.users.length + 1) {
              if (provider.isLoadingMoreUsers) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMedium,
                  ),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (provider.hasMoreUsers) {
                return OutlinedButton.icon(
                  onPressed: provider.loadMoreUsers,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more users'),
                );
              }

              return Center(
                child: Text(
                  'End of user list',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _AdminUserFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String role;
  final String accountStatus;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _AdminUserFilters({
    required this.searchController,
    required this.role,
    required this.accountStatus,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              labelText: 'Search users',
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Search',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final roleDropdown = _FilterDropdown(
                label: 'Role',
                value: role,
                items: const {
                  'all': 'All roles',
                  'user': 'Users',
                  'moderator': 'Moderators',
                  'admin': 'Admins',
                },
                onChanged: onRoleChanged,
              );
              final statusDropdown = _FilterDropdown(
                label: 'Status',
                value: accountStatus,
                items: const {
                  'all': 'All statuses',
                  'active': 'Active',
                  'deactivated': 'Deactivated',
                  'banned': 'Banned',
                },
                onChanged: onStatusChanged,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    roleDropdown,
                    const SizedBox(height: AppSizes.paddingSmall),
                    statusDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: roleDropdown),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(child: statusDropdown),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
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
