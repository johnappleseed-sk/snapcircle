import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_masonry_grid.dart';
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
  final ValueChanged<PostModel> onPostTap;

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
    required this.onPostTap,
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
          AppMasonryGrid(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return SizedBox(
                height: _previewHeight(post.id),
                child: _ProfilePostPreview(
                  post: post,
                  onTap: () => onPostTap(post),
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.paddingMedium),
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

  double _previewHeight(int postId) {
    return switch (postId % 4) {
      0 => 232,
      1 => 188,
      2 => 212,
      _ => 202,
    };
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
  final VoidCallback onTap;

  const _ProfilePostPreview({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cacheWidth =
        (MediaQuery.sizeOf(context).width /
                3 *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    final thumbnailUrl = post.media.isNotEmpty
        ? post.media.first.url
        : post.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailUrl == null
                ? Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingSmall),
                      child: Text(
                        post.content?.trim().isNotEmpty == true
                            ? post.content!
                            : 'Text post',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: cacheWidth,
                  ),
            if (post.media.length > 1)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.collections_outlined,
                  size: 18,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        '${post.likesCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_bubble,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${post.commentsCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
