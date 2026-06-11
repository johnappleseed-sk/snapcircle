import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/conversations_provider.dart';
import '../../reports/widgets/report_dialog.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_section.dart';
import '../widgets/profile_stories_section.dart';

class UserProfileScreen extends StatefulWidget {
  final int? userId;
  final String? username;

  const UserProfileScreen({super.key, this.userId, this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final profileProvider = context.read<ProfileProvider>();
    if (widget.username != null) {
      await profileProvider.fetchUserByUsername(widget.username!);
    } else if (widget.userId != null) {
      await profileProvider.fetchUserById(widget.userId!);
    }

    final user = profileProvider.selectedUser;
    if (user != null) {
      await profileProvider.fetchProfileStories(user.id, refresh: true);
      await profileProvider.fetchProfilePosts(user.id, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.selectedUser;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isCurrentUser = currentUserId != null && currentUserId == user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          if (user != null && !isCurrentUser)
            IconButton(
              onPressed: () => ReportDialog.show(
                context,
                targetType: ReportTargetType.user,
                targetId: user.id,
              ),
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Report user',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: profileProvider.isLoading && user == null
            ? const _UserProfileSkeletonList()
            : profileProvider.errorMessage != null && user == null
            ? ErrorView(
                message: profileProvider.errorMessage!,
                onRetry: _refresh,
              )
            : user == null
            ? const EmptyView(
                icon: Icons.person_search_outlined,
                title: 'User not found',
                subtitle: 'This profile may no longer exist.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  ProfileHeader(
                    user: user,
                    isOwnProfile: isCurrentUser,
                    isFollowing: profileProvider.isFollowing,
                    onEdit: isCurrentUser
                        ? () => context.push('/profile/edit')
                        : null,
                    onFollow: () async {
                      final followed = await profileProvider.followUser(
                        user.id,
                      );
                      if (!followed && context.mounted) {
                        SnackbarHelper.showError(
                          context,
                          profileProvider.errorMessage ??
                              'Unable to follow this profile.',
                        );
                      }
                    },
                    onUnfollow: () async {
                      final unfollowed = await profileProvider.unfollowUser(
                        user.id,
                      );
                      if (!unfollowed && context.mounted) {
                        SnackbarHelper.showError(
                          context,
                          profileProvider.errorMessage ??
                              'Unable to unfollow this profile.',
                        );
                      }
                    },
                    onMessage: isCurrentUser
                        ? null
                        : () async {
                            final conversation = await context
                                .read<ConversationsProvider>()
                                .startConversation(user.id);
                            if (context.mounted && conversation != null) {
                              context.push(
                                '/messages/${conversation.id}',
                                extra: conversation,
                              );
                            }
                          },
                    onFollowersTap: () =>
                        context.push('/users/${user.id}/followers'),
                    onFollowingTap: () =>
                        context.push('/users/${user.id}/following'),
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
                    isOwnProfile: isCurrentUser,
                    isLoading: profileProvider.isLoadingPosts,
                    isLoadingMore: profileProvider.isLoadingMorePosts,
                    hasMore: profileProvider.hasMorePosts,
                    currentSort: profileProvider.currentPostsSort,
                    onSortChanged: (sort) {
                      profileProvider.changePostsSort(sort);
                    },
                    onLoadMore: () =>
                        profileProvider.loadMoreProfilePosts(user.id),
                  ),
                ],
              ),
      ),
    );
  }
}

class _UserProfileSkeletonList extends StatelessWidget {
  const _UserProfileSkeletonList();

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
                    SkeletonBox(height: 14, width: 160),
                    SizedBox(height: AppSizes.paddingSmall),
                    SkeletonBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
