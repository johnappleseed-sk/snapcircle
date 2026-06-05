import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_section.dart';

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
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.fetchProfile();
    final profile = profileProvider.profile;
    if (profile != null) {
      await profileProvider.fetchProfilePosts(profile.id, refresh: true);
    }
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
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh profile',
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: profileProvider.isLoading && profile == null
            ? const LoadingView(message: 'Loading your profile...')
            : profileProvider.errorMessage != null && profile == null
            ? ErrorView(
                message: profileProvider.errorMessage!,
                onRetry: _refresh,
              )
            : profile == null
            ? const EmptyView(
                icon: Icons.person_outline,
                title: 'No profile found',
                subtitle: 'Log in again to refresh your session.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  ProfileHeader(
                    user: profile,
                    isOwnProfile: true,
                    onEdit: () => context.push('/profile/edit'),
                    onFollowersTap: () =>
                        context.push('/users/${profile.id}/followers'),
                    onFollowingTap: () =>
                        context.push('/users/${profile.id}/following'),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.bookmark_outline),
                          label: const Text('Saved Posts'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  ProfilePostsSection(
                    posts: profileProvider.profilePosts,
                    isOwnProfile: true,
                    isLoading: profileProvider.isLoadingPosts,
                    isLoadingMore: profileProvider.isLoadingMorePosts,
                    hasMore: profileProvider.hasMorePosts,
                    currentSort: profileProvider.currentPostsSort,
                    onSortChanged: (sort) {
                      profileProvider.changePostsSort(sort);
                    },
                    onLoadMore: () =>
                        profileProvider.loadMoreProfilePosts(profile.id),
                  ),
                ],
              ),
      ),
    );
  }
}
