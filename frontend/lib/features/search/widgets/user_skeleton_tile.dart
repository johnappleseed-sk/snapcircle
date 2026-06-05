import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_box.dart';

class UserSkeletonTile extends StatelessWidget {
  const UserSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          SkeletonBox(
            height: AppSizes.avatarMedium,
            width: AppSizes.avatarMedium,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 140),
                SizedBox(height: AppSizes.paddingSmall),
                SkeletonBox(height: 12, width: 210),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
