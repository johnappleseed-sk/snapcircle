import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../feed/models/post_model.dart';

class ProfilePostsSection extends StatelessWidget {
  final List<PostModel> posts;
  final bool isOwnProfile;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String currentSort;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onLoadMore;

  const ProfilePostsSection({
    super.key,
    required this.posts,
    required this.isOwnProfile,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentSort,
    required this.onSortChanged,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Posts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            _SortChip(
              label: 'Latest',
              value: 'latest',
              selectedValue: currentSort,
              onSelected: onSortChanged,
            ),
            const SizedBox(width: 8),
            _SortChip(
              label: 'Popular',
              value: 'popular',
              selectedValue: currentSort,
              onSelected: onSortChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSizes.paddingLarge),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (posts.isEmpty)
          EmptyView(
            icon: Icons.dynamic_feed_outlined,
            title: isOwnProfile ? 'You have not posted yet' : 'No posts yet',
            subtitle: isOwnProfile
                ? 'Create your first SnapCircle post to fill this space.'
                : 'This profile does not have posts to show yet.',
          )
        else ...[
          for (final post in posts) ...[
            _ProfilePostPreview(post: post),
            const SizedBox(height: AppSizes.paddingSmall),
          ],
          if (hasMore)
            OutlinedButton(
              onPressed: isLoadingMore ? null : onLoadMore,
              child: isLoadingMore
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more posts'),
            ),
        ],
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _ProfilePostPreview extends StatelessWidget {
  final PostModel post;

  const _ProfilePostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: SizedBox(
              height: 76,
              width: 76,
              child: post.imageUrl == null
                  ? Container(
                      color: AppColors.surfaceSoft,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.notes_outlined,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content?.trim().isNotEmpty == true
                      ? post.content!
                      : 'Photo post',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}'),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}'),
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
