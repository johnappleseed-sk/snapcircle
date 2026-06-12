import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/models/user_model.dart';
import 'profile_stats_row.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback? onEdit;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;
  final VoidCallback? onMessage;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isOwnProfile,
    this.isFollowing = false,
    this.onEdit,
    this.onFollow,
    this.onUnfollow,
    this.onMessage,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverImage(imageUrl: user.coverImageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -38),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: AppAvatar(
                          imageUrl: user.avatarUrl ?? user.avatar,
                          name: user.name,
                          size: AppAvatarSize.large,
                        ),
                      ),
                      const Spacer(),
                      if (isOwnProfile)
                        FilledButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        )
                      else if (user.isBlockedByMe || user.hasBlockedMe)
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.block),
                          label: Text(
                            user.isBlockedByMe ? 'Blocked' : 'Unavailable',
                          ),
                        )
                      else
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: user.allowMessages ? onMessage : null,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(
                                user.allowMessages ? 'Message' : 'Messages off',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FollowButton(
                              user: user,
                              isUpdating: isFollowing,
                              onFollow: onFollow,
                              onUnfollow: onUnfollow,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 26),
                            ),
                          ),
                          if (user.isPrivate)
                            const Icon(
                              Icons.lock_outline,
                              color: AppColors.textSecondary,
                              size: AppSizes.iconSize,
                            ),
                        ],
                      ),
                      if (user.username != null)
                        Text(
                          '@${user.username}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(user.bio!),
                      ],
                      if (user.isBlockedByMe || user.hasBlockedMe) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        _BlockedNotice(isBlockedByMe: user.isBlockedByMe),
                      ],
                      const SizedBox(height: AppSizes.paddingSmall),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (user.location != null)
                            _MetaItem(
                              icon: Icons.location_on_outlined,
                              label: user.location!,
                            ),
                          if (user.website != null)
                            _MetaItem(icon: Icons.link, label: user.website!),
                          _MetaItem(
                            icon: Icons.calendar_month_outlined,
                            label: user.joinedAt == null
                                ? 'Joined SnapCircle'
                                : 'Joined ${DateFormatter.timeAgo(user.joinedAt)}',
                          ),
                        ],
                      ),
                      if (isOwnProfile) ...[
                        const SizedBox(height: AppSizes.paddingMedium),
                        _CompletionBar(value: user.profileCompletion),
                      ],
                      const SizedBox(height: AppSizes.paddingMedium),
                      ProfileStatsRow(
                        postsCount: user.postsCount,
                        followersCount: user.followersCount,
                        followingCount: user.followingCount,
                        onFollowersTap: onFollowersTap,
                        onFollowingTap: onFollowingTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final UserModel user;
  final bool isUpdating;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;

  const _FollowButton({
    required this.user,
    required this.isUpdating,
    required this.onFollow,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    if (user.followStatus == 'requested' || user.hasRequestedFollow) {
      return OutlinedButton.icon(
        onPressed: isUpdating ? null : onUnfollow,
        icon: const Icon(Icons.hourglass_top_outlined),
        label: Text(isUpdating ? 'Updating...' : 'Requested'),
      );
    }

    if (user.isFollowedByMe || user.followStatus == 'following') {
      return OutlinedButton(
        onPressed: isUpdating ? null : onUnfollow,
        child: Text(isUpdating ? 'Updating...' : 'Unfollow'),
      );
    }

    return FilledButton(
      onPressed: isUpdating ? null : onFollow,
      child: Text(isUpdating ? 'Updating...' : 'Follow'),
    );
  }
}

class _BlockedNotice extends StatelessWidget {
  final bool isBlockedByMe;

  const _BlockedNotice({required this.isBlockedByMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isBlockedByMe
                  ? 'You blocked this user. Their posts and messages are hidden.'
                  : 'This profile is not available for messaging or following.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? imageUrl;

  const _CoverImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusMedium),
      ),
      child: SizedBox(
        height: 150,
        child: url == null || url.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.accent.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              )
            : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  final int value;

  const _CompletionBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profile completion',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text('$value%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value.clamp(0, 100).toDouble() / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
