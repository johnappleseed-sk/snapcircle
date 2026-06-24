import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../reports/widgets/report_dialog.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import 'hashtag_caption.dart';
import 'post_media_carousel.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onTap;
  final Future<bool> Function()? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBlockUser;
  final ValueChanged<String>? onTagTap;

  const PostCard({
    super.key,
    required this.post,
    this.canDelete = false,
    this.onDelete,
    this.onEdit,
    this.onCommentsTap,
    this.onTap,
    this.onSaveTap,
    this.onShareTap,
    this.onBlockUser,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = post.content != null && post.content!.trim().isNotEmpty;
    final hasMedia = post.media.isNotEmpty;
    final isLikeUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isLikeUpdating(post.id),
    );
    final isSaveUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isSaveUpdating(post.id),
    );
    final username = post.user.username?.trim();
    final subtitle = [
      if (username != null && username.isNotEmpty) '@$username',
      DateFormatter.timeAgo(post.createdAt),
    ].join(' - ');
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 14,
        14,
        isCompact ? 12 : 14,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: post.user.name,
                imageUrl: post.user.avatarUrl ?? post.user.avatar,
                size: AppAvatarSize.medium,
              ),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete || post.canUpdate || !post.isOwner)
                IconButton(
                  onPressed: () => _showPostActions(context),
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Post options',
                ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            HashtagCaption(
              text: post.content!,
              onTagTap: onTagTap ?? (tag) => _openTag(context, tag),
            ),
          ],
          if (hasMedia) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            PostMediaCarousel(media: post.media),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              _PostAction(
                icon: post.likedByMe
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                label: post.likesCount.toString(),
                color: post.likedByMe ? AppColors.danger : null,
                isLoading: isLikeUpdating,
                compact: isCompact,
                semanticLabel: post.likedByMe ? 'Unlike post' : 'Like post',
                onTap: isLikeUpdating
                    ? null
                    : () async {
                        final success = await context
                            .read<FeedProvider>()
                            .toggleLike(post.id);
                        if (!success && context.mounted) {
                          final message = context
                              .read<FeedProvider>()
                              .errorMessage;
                          if (message != null) {
                            SnackbarHelper.showError(context, message);
                          }
                        }
                      },
              ),
              _PostAction(
                icon: Icons.chat_bubble_outline,
                label: post.commentsCount.toString(),
                compact: isCompact,
                semanticLabel: 'Open comments',
                onTap: onCommentsTap,
              ),
              _PostAction(
                icon: Icons.ios_share_outlined,
                label: 'Share',
                compact: isCompact,
                semanticLabel: 'Share post',
                onTap:
                    onShareTap ??
                    () => context.read<FeedProvider>().sharePost(post),
              ),
              const Spacer(),
              _PostAction(
                icon: post.savedByMe
                    ? Icons.bookmark
                    : Icons.bookmark_border_outlined,
                label: post.savesCount.toString(),
                color: post.savedByMe ? AppColors.primary : null,
                isLoading: isSaveUpdating,
                compact: isCompact,
                semanticLabel: post.savedByMe ? 'Unsave post' : 'Save post',
                onTap: isSaveUpdating
                    ? null
                    : () async {
                        final success =
                            await (onSaveTap?.call() ??
                                context.read<FeedProvider>().toggleSave(
                                  post.id,
                                ));
                        if (!success && context.mounted) {
                          final message = context
                              .read<FeedProvider>()
                              .errorMessage;
                          if (message != null) {
                            SnackbarHelper.showError(context, message);
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTag(BuildContext context, String tag) {
    context.go('/explore/tags/${Uri.encodeComponent(tag)}');
  }

  Future<void> _showPostActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.canUpdate)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit post'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onEdit?.call();
                    },
                  ),
                if (canDelete)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    title: const Text('Delete post'),
                    textColor: AppColors.danger,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDelete?.call();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('View profile'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/users/${post.user.id}');
                  },
                ),
                if (post.content != null && post.content!.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy post text'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await Clipboard.setData(
                        ClipboardData(text: post.content!.trim()),
                      );
                      if (context.mounted) {
                        SnackbarHelper.showSuccess(
                          context,
                          'Post text copied.',
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: Icon(
                    post.savedByMe
                        ? Icons.bookmark_remove_outlined
                        : Icons.bookmark_add_outlined,
                  ),
                  title: Text(post.savedByMe ? 'Unsave post' : 'Save post'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final success =
                        await (onSaveTap?.call() ??
                            context.read<FeedProvider>().toggleSave(post.id));
                    if (!context.mounted) {
                      return;
                    }
                    if (success) {
                      SnackbarHelper.showSuccess(
                        context,
                        post.savedByMe ? 'Post unsaved.' : 'Post saved.',
                      );
                    } else {
                      final message = context.read<FeedProvider>().errorMessage;
                      if (message != null) {
                        SnackbarHelper.showError(context, message);
                      }
                    }
                  },
                ),
                if (!post.isOwner && onBlockUser != null)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report post'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ReportDialog.show(
                        context,
                        targetType: ReportTargetType.post,
                        targetId: post.id,
                      );
                    },
                  ),
                if (!post.isOwner)
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Block user'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onBlockUser?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PostWaterfallCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentsTap;
  final Future<bool> Function()? onSaveTap;
  final ValueChanged<String>? onTagTap;

  const PostWaterfallCard({
    super.key,
    required this.post,
    this.onTap,
    this.onCommentsTap,
    this.onSaveTap,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = post.media.isNotEmpty
        ? post.media.first.url
        : post.imageUrl;
    final title = post.content?.trim().isNotEmpty == true
        ? post.content!.trim()
        : 'A SnapCircle moment';
    final aspectRatio = _aspectRatioFor(post.id, thumbnailUrl != null);
    final isLikeUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isLikeUpdating(post.id),
    );
    final isSaveUpdating = context.select<FeedProvider, bool>(
      (provider) => provider.isSaveUpdating(post.id),
    );

    return Semantics(
      button: true,
      label: 'Open post by ${post.user.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.07,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl == null)
                      _WaterfallTextPreview(text: title)
                    else
                      CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        memCacheWidth:
                            (260 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        placeholder: (_, _) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, _, _) =>
                            _WaterfallTextPreview(text: title),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                          stops: const [0, 0.54, 1],
                        ),
                      ),
                    ),
                    if (post.media.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _OverlayPill(
                          icon: Icons.collections_outlined,
                          label: '${post.media.length}',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HashtagCaption(
                      text: title,
                      maxLines: 2,
                      onTagTap: onTagTap ?? (tag) => _openTag(context, tag),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        AppAvatar(
                          name: post.user.name,
                          imageUrl: post.user.avatarUrl ?? post.user.avatar,
                          size: AppAvatarSize.small,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            post.user.name.isEmpty
                                ? 'SnapCircle User'
                                : post.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _MiniAction(
                          icon: post.likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          label: _compactCount(post.likesCount),
                          color: post.likedByMe ? AppColors.danger : null,
                          isLoading: isLikeUpdating,
                          onTap: isLikeUpdating
                              ? null
                              : () => context.read<FeedProvider>().toggleLike(
                                  post.id,
                                ),
                        ),
                        _MiniAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: _compactCount(post.commentsCount),
                          onTap: onCommentsTap,
                        ),
                        const Spacer(),
                        _MiniAction(
                          icon: post.savedByMe
                              ? Icons.bookmark
                              : Icons.bookmark_border_rounded,
                          label: _compactCount(post.savesCount),
                          color: post.savedByMe ? AppColors.primary : null,
                          isLoading: isSaveUpdating,
                          onTap: isSaveUpdating
                              ? null
                              : () =>
                                    onSaveTap?.call() ??
                                    context.read<FeedProvider>().toggleSave(
                                      post.id,
                                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTag(BuildContext context, String tag) {
    context.go('/explore/tags/${Uri.encodeComponent(tag)}');
  }

  double _aspectRatioFor(int id, bool hasImage) {
    if (!hasImage) {
      return 1.05;
    }
    return switch (id % 5) {
      0 => 0.72,
      1 => 0.82,
      2 => 0.94,
      3 => 0.78,
      _ => 0.88,
    };
  }

  String _compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _WaterfallTextPreview extends StatelessWidget {
  final String text;

  const _WaterfallTextPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.13),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          height: 1.22,
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OverlayPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final FutureOr<void> Function()? onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_MiniAction> createState() => _MiniActionState();
}

class _MiniActionState extends State<_MiniAction> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null || widget.isLoading) {
      return;
    }
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _pressed = false);
    }
    await onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.58);
    return AnimatedScale(
      scale: _pressed ? 0.9 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: widget.onTap == null || widget.isLoading ? null : _handleTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: widget.isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 18, color: color),
                    const SizedBox(width: 3),
                    Text(
                      widget.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PostAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final bool compact;
  final String semanticLabel;
  final FutureOr<void> Function()? onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.color,
    this.compact = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_PostAction> createState() => _PostActionState();
}

class _PostActionState extends State<_PostAction> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null || widget.isLoading) {
      return;
    }

    setState(() => _isPressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _isPressed = false);
    }
    await onTap();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.color ?? AppColors.mutedText;
    final hasAccent = widget.color != null;
    final visibleLabel = widget.compact && widget.label.length > 3
        ? ''
        : widget.label;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        child: AnimatedScale(
          scale: _isPressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            onTap: widget.isLoading || widget.onTap == null ? null : _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: hasAccent
                    ? foreground.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: widget.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        key: ValueKey('${widget.icon}-$visibleLabel'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 22, color: foreground),
                          if (visibleLabel.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Text(
                              visibleLabel,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
