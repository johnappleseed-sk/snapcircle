import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../auth/models/user_model.dart';
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

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.username != widget.username) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh();
      });
    }
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
      if (_canViewPrivateContent(user)) {
        await profileProvider.fetchProfileStories(user.id, refresh: true);
        await profileProvider.fetchProfilePosts(user.id, refresh: true);
      } else {
        profileProvider.clearPrivateProfileContent();
      }
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
            PopupMenuButton<String>(
              tooltip: 'Profile options',
              onSelected: (value) {
                if (value == 'report') {
                  ReportDialog.show(
                    context,
                    targetType: ReportTargetType.user,
                    targetId: user.id,
                  );
                }
                if (value == 'block') {
                  _confirmBlock(user.id);
                }
                if (value == 'unblock') {
                  _confirmUnblock(user.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined),
                      SizedBox(width: 8),
                      Text('Report user'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: user.isBlockedByMe ? 'unblock' : 'block',
                  child: Row(
                    children: [
                      Icon(user.isBlockedByMe ? Icons.lock_open : Icons.block),
                      const SizedBox(width: 8),
                      Text(user.isBlockedByMe ? 'Unblock user' : 'Block user'),
                    ],
                  ),
                ),
              ],
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
                      if (!context.mounted) {
                        return;
                      }
                      final updatedUser = profileProvider.selectedUser;
                      if (followed &&
                          updatedUser?.followStatus == 'requested') {
                        SnackbarHelper.showSuccess(
                          context,
                          'Follow request sent.',
                        );
                      } else if (followed) {
                        SnackbarHelper.showSuccess(context, 'Following.');
                        await _refresh();
                      } else {
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
                      if (!context.mounted) {
                        return;
                      }
                      if (unfollowed) {
                        SnackbarHelper.showSuccess(
                          context,
                          user.followStatus == 'requested'
                              ? 'Follow request cancelled.'
                              : 'Unfollowed.',
                        );
                        if (profileProvider.selectedUser != null &&
                            !_canViewPrivateContent(
                              profileProvider.selectedUser!,
                            )) {
                          profileProvider.clearPrivateProfileContent();
                        }
                      } else {
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
                            } else if (context.mounted) {
                              final message = context
                                  .read<ConversationsProvider>()
                                  .errorMessage;
                              if (message != null) {
                                SnackbarHelper.showError(context, message);
                              }
                            }
                          },
                    onFollowersTap: () =>
                        context.push('/users/${user.id}/followers'),
                    onFollowingTap: () =>
                        context.push('/users/${user.id}/following'),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  if (user.isBlockedByMe || user.hasBlockedMe)
                    const SizedBox.shrink()
                  else if (!_canViewPrivateContent(user))
                    const _PrivateProfileNotice()
                  else ...[
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
                      onPostTap: (post) =>
                          context.push('/posts/${post.id}', extra: post),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  bool _canViewPrivateContent(UserModel user) {
    return user.isMe ||
        !user.isPrivate ||
        user.isFollowedByMe ||
        user.followStatus == 'following';
  }

  Future<void> _confirmBlock(int userId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Block this user?',
      message:
          'They will not be able to follow or message you, and their posts will be hidden.',
      confirmLabel: 'Block',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<ProfileProvider>().blockUser(userId);
    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'User blocked.');
    } else {
      SnackbarHelper.showError(
        context,
        context.read<ProfileProvider>().errorMessage ??
            'Unable to block this user.',
      );
    }
  }

  Future<void> _confirmUnblock(int userId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Unblock this user?',
      message: 'They may be able to follow or message you again.',
      confirmLabel: 'Unblock',
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<ProfileProvider>().unblockUser(userId);
    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'User unblocked.');
      await _refresh();
    } else {
      SnackbarHelper.showError(
        context,
        context.read<ProfileProvider>().errorMessage ??
            'Unable to unblock this user.',
      );
    }
  }
}

class _PrivateProfileNotice extends StatelessWidget {
  const _PrivateProfileNotice();

  @override
  Widget build(BuildContext context) {
    return const EmptyView(
      icon: Icons.lock_outline,
      title: 'This account is private',
      subtitle: 'Follow this user to see their posts and stories.',
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
