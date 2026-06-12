import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/models/user_model.dart';

class RecommendedUserCard extends StatelessWidget {
  final UserModel user;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  const RecommendedUserCard({
    super.key,
    required this.user,
    required this.isUpdating,
    required this.onTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = user.bio?.trim().isNotEmpty == true
        ? user.bio!
        : user.username != null
        ? '@${user.username}'
        : user.location ?? (user.showEmail ? user.email : 'SnapCircle user');

    return SizedBox(
      width: 178,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              name: user.name,
              imageUrl: user.avatar,
              size: AppAvatarSize.large,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (user.isPrivate) ...[
              const SizedBox(height: 2),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              '${user.followersCount} followers',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            AppButton(
              label: user.isFollowedByMe
                  ? 'Following'
                  : user.hasRequestedFollow || user.followStatus == 'requested'
                  ? 'Requested'
                  : 'Follow',
              variant:
                  user.isFollowedByMe ||
                      user.hasRequestedFollow ||
                      user.followStatus == 'requested'
                  ? AppButtonVariant.outline
                  : AppButtonVariant.primary,
              isLoading: isUpdating,
              onPressed: onFollowTap,
            ),
          ],
        ),
      ),
    );
  }
}
