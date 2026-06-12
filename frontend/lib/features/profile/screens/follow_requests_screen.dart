import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../providers/profile_provider.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchFollowRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Follow Requests')),
      body: RefreshIndicator(
        onRefresh: provider.fetchFollowRequests,
        child: provider.isLoadingFollowRequests && provider.followRequests.isEmpty
            ? const LoadingView(message: 'Loading follow requests...')
            : provider.errorMessage != null && provider.followRequests.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  ErrorView(
                    message: provider.errorMessage!,
                    onRetry: provider.fetchFollowRequests,
                  ),
                ],
              )
            : provider.followRequests.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: const [
                  SizedBox(height: 96),
                  EmptyView(
                    icon: Icons.person_add_alt_outlined,
                    title: 'No follow requests',
                    subtitle: 'New requests will appear here.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                itemCount: provider.followRequests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSizes.paddingSmall),
                itemBuilder: (context, index) {
                  final user = provider.followRequests[index];
                  return AppCard(
                    child: Row(
                      children: [
                        AppAvatar(
                          name: user.name,
                          imageUrl: user.avatarUrl ?? user.avatar,
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
                              if (user.username != null)
                                Text(
                                  '@${user.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: provider.isFollowing
                              ? null
                              : () => _reject(context, user.id),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          onPressed: provider.isFollowing
                              ? null
                              : () => _approve(context, user.id),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, int userId) async {
    final success = await context
        .read<ProfileProvider>()
        .approveFollowRequest(userId);
    if (!context.mounted) return;

    success
        ? SnackbarHelper.showSuccess(context, 'Follow request approved.')
        : SnackbarHelper.showError(
            context,
            context.read<ProfileProvider>().errorMessage ??
                'Unable to approve request.',
          );
  }

  Future<void> _reject(BuildContext context, int userId) async {
    final success = await context
        .read<ProfileProvider>()
        .rejectFollowRequest(userId);
    if (!context.mounted) return;

    success
        ? SnackbarHelper.showSuccess(context, 'Follow request rejected.')
        : SnackbarHelper.showError(
            context,
            context.read<ProfileProvider>().errorMessage ??
                'Unable to reject request.',
          );
  }
}
