import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/skeleton_box.dart';

class StorySkeletonCircle extends StatelessWidget {
  const StorySkeletonCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 74,
      child: Column(
        children: [
          SkeletonBox(
            height: 62,
            width: 62,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(height: AppSizes.paddingSmall),
          SkeletonBox(height: 10, width: 52),
        ],
      ),
    );
  }
}
