import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/hashtag_utils.dart';
import '../../feed/models/post_model.dart';

class ExplorePostGridItem extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const ExplorePostGridItem({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (180 * MediaQuery.devicePixelRatioOf(context)).round();
    final thumbnailUrl = post.media.isNotEmpty
        ? post.media.first.url
        : post.imageUrl;
    final tags = HashtagUtils.extract(post.content ?? '');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
                placeholder: (_, _) => Container(color: AppColors.border),
                errorWidget: (_, _, _) => _TextPreview(post: post),
              )
            else
              _TextPreview(post: post),
            const Positioned.fill(child: _MediaOverlay()),
            if (tags.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                right: post.media.length > 1 ? 36 : 8,
                child: _TagPill(tag: tags.first),
              ),
            if (post.media.length > 1)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.collections_outlined,
                  color: Colors.white,
                  size: 19,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  _Metric(icon: Icons.favorite, value: post.likesCount),
                  const SizedBox(width: 8),
                  _Metric(icon: Icons.chat_bubble, value: post.commentsCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String tag;

  const _TagPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 116),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#$tag',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final PostModel post;

  const _TextPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Text(
          post.content?.trim().isNotEmpty == true
              ? post.content!
              : 'SnapCircle post',
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MediaOverlay extends StatelessWidget {
  const _MediaOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.04),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.42),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final int value;

  const _Metric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
