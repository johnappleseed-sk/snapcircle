import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/stories_provider.dart';
import 'story_skeleton_circle.dart';
import 'story_circle.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoriesProvider>();
    final hasStories = provider.stories.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 1 + (provider.isLoading ? 4 : provider.stories.length),
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              if (index == 0) {
                return StoryCircle(
                  label: 'Your story',
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
        ),
        if (!provider.isLoading && !hasStories) ...[
          const SizedBox(height: 2),
          Text(
            'Add a story to start the row.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
