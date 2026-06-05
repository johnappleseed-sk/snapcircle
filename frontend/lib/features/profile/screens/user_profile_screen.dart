import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchUserById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final selectedUser = profileProvider.selectedUser;
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: RefreshIndicator(
        onRefresh: () => profileProvider.fetchUserById(widget.userId),
        child: _UserProfileBody(
          user: selectedUser,
          currentUserId: currentUserId,
          isLoading: profileProvider.isLoading,
          isFollowing: profileProvider.isFollowing,
          errorMessage: profileProvider.errorMessage,
          onRetry: () => profileProvider.fetchUserById(widget.userId),
        ),
      ),
    );
  }
}

class _UserProfileBody extends StatelessWidget {
  final UserModel? user;
  final int? currentUserId;
  final bool isLoading;
  final bool isFollowing;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _UserProfileBody({
    required this.user,
    required this.currentUserId,
    required this.isLoading,
    required this.isFollowing,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && user == null) {
      return const LoadingView(message: 'Loading profile...');
    }

    if (errorMessage != null && user == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          const SizedBox(height: 96),
          ErrorView(message: errorMessage!, onRetry: onRetry),
        ],
      );
    }

    if (user == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: const [
          SizedBox(height: 96),
          Center(child: Text('User not found.')),
        ],
      );
    }

    final loadedUser = user!;
    final isCurrentUser =
        currentUserId != null && currentUserId == loadedUser.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingXL,
      ),
      children: [
        AppCard(
          child: Column(
            children: [
              AppAvatar(
                name: loadedUser.name,
                imageUrl: loadedUser.avatar,
                size: AppAvatarSize.extraLarge,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                loadedUser.name,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (loadedUser.bio != null &&
                  loadedUser.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingSmall),
                Text(loadedUser.bio!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSizes.paddingMedium),
              Row(
                children: [
                  Expanded(
                    child: _StatButton(
                      label: 'Posts',
                      value: loadedUser.postsCount,
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      label: 'Followers',
                      value: loadedUser.followersCount,
                      onTap: () => _openFollowList(context, 'followers'),
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      label: 'Following',
                      value: loadedUser.followingCount,
                      onTap: () => _openFollowList(context, 'following'),
                    ),
                  ),
                ],
              ),
              if (!isCurrentUser) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                AppButton(
                  label: loadedUser.isFollowedByMe ? 'Unfollow' : 'Follow',
                  icon: loadedUser.isFollowedByMe
                      ? Icons.person_remove_outlined
                      : Icons.person_add_outlined,
                  variant: loadedUser.isFollowedByMe
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  isLoading: isFollowing,
                  onPressed: isFollowing
                      ? null
                      : () => loadedUser.isFollowedByMe
                            ? context.read<ProfileProvider>().unfollowUser(
                                loadedUser.id,
                              )
                            : context.read<ProfileProvider>().followUser(
                                loadedUser.id,
                              ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        const AppCard(
          child: Text(
            'User posts will be improved later.',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }

  void _openFollowList(BuildContext context, String type) {
    context.push('/users/${user!.id}/$type');
  }
}

class _StatButton extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _StatButton({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
