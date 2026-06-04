import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentsTap;

  const PostCard({
    super.key,
    required this.post,
    this.canDelete = false,
    this.onDelete,
    this.onCommentsTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = post.content != null && post.content!.trim().isNotEmpty;
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(imageUrl: post.user.avatar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.name.isEmpty
                          ? 'SnapCircle User'
                          : post.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.timeAgo(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Post options',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: 14),
            Text(
              post.content!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.35,
                color: AppColors.text,
              ),
            ),
          ],
          if (hasImage) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _PostMetric(
                icon: post.likedByMe
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                label: post.likesCount.toString(),
                color: post.likedByMe ? AppColors.danger : AppColors.mutedText,
              ),
              const SizedBox(width: 18),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onCommentsTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _PostMetric(
                    icon: Icons.chat_bubble_outline,
                    label: post.commentsCount.toString(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;

  const _UserAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          height: 44,
          width: 44,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const _AvatarFallback(),
          placeholder: (context, url) => const _AvatarFallback(),
        ),
      );
    }

    return const _AvatarFallback();
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppColors.mutedText),
    );
  }
}

class _PostMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PostMetric({
    required this.icon,
    required this.label,
    this.color = AppColors.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
