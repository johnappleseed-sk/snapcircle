import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/models/user_model.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    final handle = user.username == null ? null : '@${user.username}';
    final subtitle = user.bio != null && user.bio!.trim().isNotEmpty
        ? user.bio!
        : user.location ??
              (handle ?? (user.showEmail ? user.email : 'SnapCircle user'));
    final secondaryText = handle == null || subtitle == handle
        ? subtitle
        : '$handle · $subtitle';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(imageUrl: user.avatar, name: user.name),
          const SizedBox(width: AppSizes.paddingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  secondaryText,
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Wrap(
                  spacing: AppSizes.paddingSmall,
                  runSpacing: AppSizes.paddingXS,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (user.isPrivate)
                      const _UserMetaPill(
                        icon: Icons.lock_outline,
                        label: 'Private',
                      ),
                    if (user.isFollowedByMe ||
                        user.hasRequestedFollow ||
                        user.followStatus == 'requested')
                      _UserStatusPill(
                        label: user.isFollowedByMe ? 'Following' : 'Requested',
                      ),
                    _UserMetaPill(
                      icon: Icons.people_outline,
                      label: '${user.followersCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserStatusPill extends StatelessWidget {
  final String label;

  const _UserStatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _UserMetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
