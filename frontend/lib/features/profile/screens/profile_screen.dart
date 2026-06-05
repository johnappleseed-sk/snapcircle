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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.profile == null) {
        profileProvider.fetchProfile();
      }
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: profileProvider.fetchProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: profileProvider.fetchProfile,
        child: _ProfileBody(
          profile: profile,
          isLoading: profileProvider.isLoading,
          errorMessage: profileProvider.errorMessage,
          onRetry: profileProvider.fetchProfile,
          onLogout: _logout,
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserModel? profile;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const _ProfileBody({
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && profile == null) {
      return const LoadingView(message: 'Loading profile...');
    }

    if (errorMessage != null && profile == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          const SizedBox(height: 96),
          ErrorView(message: errorMessage!, onRetry: onRetry),
        ],
      );
    }

    if (profile == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: const [
          SizedBox(height: 96),
          Center(child: Text('No profile found.')),
        ],
      );
    }

    final loadedProfile = profile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingXL,
      ),
      children: [
        _ProfileHeader(user: loadedProfile),
        const SizedBox(height: AppSizes.paddingMedium),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                onPressed: () => context.push('/profile/edit'),
              ),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            Expanded(
              child: AppButton(
                label: 'Logout',
                icon: Icons.logout,
                variant: AppButtonVariant.outline,
                onPressed: onLogout,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        AppCard(
          onTap: () => context.push('/saved-posts'),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: const Icon(
                  Icons.bookmark_border_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Posts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Revisit posts you saved for later.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _PostsPlaceholder(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          AppAvatar(
            name: user.name,
            imageUrl: user.avatar,
            size: AppAvatarSize.extraLarge,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _StatItem(label: 'Posts', value: user.postsCount),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Followers',
                  value: user.followersCount,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Following',
                  value: user.followingCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _PostsPlaceholder extends StatelessWidget {
  const _PostsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'User posts will be improved later.',
        style: TextStyle(color: AppColors.mutedText),
      ),
    );
  }
}
