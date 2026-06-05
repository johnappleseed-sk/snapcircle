import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/conversations_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_section.dart';

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
      appBar: AppBar(title: const Text('User Profile')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: profileProvider.isLoading && user == null
            ? const LoadingView(message: 'Loading user profile...')
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
                    onFollow: () {
                      profileProvider.followUser(user.id);
                    },
                    onUnfollow: () {
                      profileProvider.unfollowUser(user.id);
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
