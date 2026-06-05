import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../providers/stories_provider.dart';
import 'story_skeleton_circle.dart';
import 'story_circle.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoriesProvider>();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + (provider.isLoading ? 4 : provider.stories.length),
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSizes.paddingSmall),
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoryCircle(
              label: 'Your Story',
              isAddItem: true,
              onTap: () => context.push('/stories/create'),
            );
          }

          if (provider.isLoading) {
            return const StorySkeletonCircle();
          }

          final story = provider.stories[index - 1];
          return StoryCircle(
            label: story.user.name,
            imageUrl: story.mediaUrl ?? story.user.avatar,
            isViewed: story.viewedByMe,
            onTap: () => context.push('/stories/${story.id}', extra: story),
          );
        },
      ),
    );
  }
}
