import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../stories/models/story_model.dart';
import '../../stories/widgets/story_circle.dart';

class ProfileStoriesSection extends StatelessWidget {
  final List<StoryModel> stories;
  final bool isLoading;
  final String? errorMessage;

  const ProfileStoriesSection({
    super.key,
    required this.stories,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stories',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        if (isLoading)
          const SizedBox(
            height: 88,
            child: Row(
              children: [
                SkeletonBox(
                  height: 64,
                  width: 64,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                SizedBox(width: AppSizes.paddingSmall),
                SkeletonBox(
                  height: 64,
                  width: 64,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                SizedBox(width: AppSizes.paddingSmall),
                SkeletonBox(
                  height: 64,
                  width: 64,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
              ],
            ),
          )
        else if (errorMessage != null)
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (stories.isEmpty)
          Text(
            'No active stories.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSizes.paddingSmall),
              itemBuilder: (context, index) {
                final story = stories[index];
                return StoryCircle(
                  label: story.user.name,
                  imageUrl: story.mediaUrl ?? story.user.avatarUrl,
                  isViewed: story.viewedByMe,
                  onTap: () =>
                      context.push('/stories/${story.id}', extra: story),
                );
              },
            ),
          ),
      ],
    );
  }
}
