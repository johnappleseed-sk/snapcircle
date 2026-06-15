import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../profile/providers/profile_provider.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: RefreshIndicator(
        onRefresh: provider.fetchBlockedUsers,
        child: provider.isLoadingBlockedUsers && provider.blockedUsers.isEmpty
            ? const LoadingView(message: 'Loading blocked users...')
            : provider.errorMessage != null && provider.blockedUsers.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  ErrorView(
                    message: provider.errorMessage!,
                    onRetry: provider.fetchBlockedUsers,
                  ),
                ],
              )
            : provider.blockedUsers.isEmpty
            ? const EmptyView(
                icon: Icons.block,
                title: "You haven't blocked anyone.",
                subtitle:
                    'People you block will appear here so you can unblock them later.',
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSizes.paddingMedium,
                  horizontalPadding,
                  AppSizes.paddingXL,
                ),
                itemCount: provider.blockedUsers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.paddingSmall),
                itemBuilder: (context, index) {
                  final user = provider.blockedUsers[index];
                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: user.name,
                          imageUrl: user.avatarUrl ?? user.avatar,
                          size: AppAvatarSize.small,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                user.username == null
                                    ? user.email
                                    : '@${user.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        OutlinedButton(
                          onPressed: provider.isBlocking
                              ? null
                              : () => _confirmUnblock(user.id),
                          child: const Text('Unblock'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmUnblock(int userId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Unblock this user?',
      message: 'They may be able to follow or message you again.',
      confirmLabel: 'Unblock',
    );

    if (!confirmed || !mounted) return;

    final provider = context.read<ProfileProvider>();
    final success = await provider.unblockUser(userId);
    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'User unblocked.');
    } else {
      SnackbarHelper.showError(
        context,
        provider.errorMessage ?? 'Unable to unblock this user.',
      );
    }
  }
}
