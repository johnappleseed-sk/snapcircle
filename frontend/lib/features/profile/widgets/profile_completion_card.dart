import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/models/user_model.dart';

class ProfileCompletionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditProfile;

  const ProfileCompletionCard({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final missingItems = _missingItems;
    if (user.profileCompletion >= 90 || missingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final completion = user.profileCompletion.clamp(0, 100);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your profile',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completion% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onEditProfile, child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          LinearProgressIndicator(
            value: completion / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Add ${missingItems.take(3).join(', ')} so people know who they are connecting with.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _missingItems {
    final items = <String>[];
    if ((user.avatarUrl ?? user.avatar ?? '').trim().isEmpty) {
      items.add('a profile photo');
    }
    if ((user.username ?? '').trim().isEmpty) {
      items.add('a username');
    }
    if ((user.bio ?? '').trim().isEmpty) {
      items.add('a bio');
    }
    if ((user.location ?? '').trim().isEmpty) {
      items.add('your location');
    }
    if ((user.website ?? '').trim().isEmpty) {
      items.add('a link');
    }
    return items;
  }
}
