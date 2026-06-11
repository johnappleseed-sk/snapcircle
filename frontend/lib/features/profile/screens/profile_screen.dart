import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/profile_posts_section.dart';
import '../widgets/profile_stories_section.dart';

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
      await profileProvider.fetchProfileStories(profile.id, refresh: true);
      await profileProvider.fetchProfilePosts(profile.id, refresh: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Log out?',
      message: 'You can sign back in any time.',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

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
            ? const _ProfileSkeletonList()
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
                  ProfileCompletionCard(
                    user: profile,
                    onEditProfile: () => context.push('/profile/edit'),
                  ),
                  if (profile.profileCompletion < 90)
                    const SizedBox(height: AppSizes.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/saved-posts'),
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
                  ProfileStoriesSection(
                    stories: profileProvider.profileStories,
                    isLoading: profileProvider.isLoadingStories,
                    errorMessage: profileProvider.storiesErrorMessage,
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

class _ProfileSkeletonList extends StatelessWidget {
  const _ProfileSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: const [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 150),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(
                          height: 72,
                          width: 72,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                        SizedBox(width: AppSizes.paddingMedium),
                        Expanded(child: SkeletonBox(height: 18)),
                      ],
                    ),
                    SizedBox(height: AppSizes.paddingMedium),
                    SkeletonBox(height: 14, width: 180),
                    SizedBox(height: AppSizes.paddingSmall),
                    SkeletonBox(height: 14),
                    SizedBox(height: AppSizes.paddingLarge),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 44)),
                        SizedBox(width: AppSizes.paddingSmall),
                        Expanded(child: SkeletonBox(height: 44)),
                        SizedBox(width: AppSizes.paddingSmall),
                        Expanded(child: SkeletonBox(height: 44)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.paddingLarge),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 112)),
            SizedBox(width: 3),
            Expanded(child: SkeletonBox(height: 112)),
            SizedBox(width: 3),
            Expanded(child: SkeletonBox(height: 112)),
          ],
        ),
      ],
    );
  }
}
