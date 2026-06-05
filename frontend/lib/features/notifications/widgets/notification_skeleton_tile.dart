import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_box.dart';

class NotificationSkeletonTile extends StatelessWidget {
  const NotificationSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 40,
            width: 40,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 13, width: 230),
                SizedBox(height: AppSizes.paddingSmall),
                SkeletonBox(height: 12, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
