import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/story_repository.dart';
import '../models/story_model.dart';
import '../providers/stories_provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final int storyId;
  final StoryModel? initialStory;

  const StoryViewerScreen({
    super.key,
    required this.storyId,
    this.initialStory,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final _repository = StoryRepository();
  final _replyController = TextEditingController();
  StoryModel? _story;
  bool _isLoading = false;
  bool _isSendingReply = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _story = widget.initialStory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoryIfNeeded();
      context.read<StoriesProvider>().markStoryAsViewed(widget.storyId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryIfNeeded() async {
    if (_story != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final story = await _repository.getStory(widget.storyId);
      if (mounted) {
        setState(() => _story = story);
      }
    } on StoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load story.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openStory(StoryModel story) async {
    setState(() {
      _story = story;
      _errorMessage = null;
      _isLoading = false;
    });
    await context.read<StoriesProvider>().markStoryAsViewed(story.id);
  }

  Future<void> _goToAdjacentStory(int direction) async {
    final current = _story;
    if (current == null) {
      return;
    }

    final provider = context.read<StoriesProvider>();
    final stories = provider.stories;
    final index = stories.indexWhere((story) => story.id == current.id);
    if (index == -1) {
      return;
    }

    final nextIndex = index + direction;
    if (nextIndex >= 0 && nextIndex < stories.length) {
      await _openStory(stories[nextIndex]);
      return;
    }

    if (direction > 0 && provider.hasMore) {
      await provider.loadMoreStories();
      if (!mounted) {
        return;
      }
      final updatedStories = context.read<StoriesProvider>().stories;
      final updatedIndex = updatedStories.indexWhere(
        (story) => story.id == current.id,
      );
      final loadedNextIndex = updatedIndex + direction;
      if (updatedIndex != -1 && loadedNextIndex < updatedStories.length) {
        await _openStory(updatedStories[loadedNextIndex]);
      }
    }
  }

  Future<void> _toggleReaction(String reaction) async {
    final story = _story;
    if (story == null) {
      return;
    }

    final provider = context.read<StoriesProvider>();
    final selected = story.myReaction == reaction;
    final ok = selected
        ? await provider.removeStoryReaction(story.id)
        : await provider.reactToStory(story.id, reaction);

    if (!mounted) {
      return;
    }

    if (!ok) {
      SnackbarHelper.showError(
        context,
        provider.errorMessage ?? 'Unable to update reaction.',
      );
      return;
    }

    final updated = _storyFromProvider(story.id);
    setState(() {
      _story =
          updated ??
          story.copyWith(
            myReaction: selected ? null : reaction,
            clearMyReaction: selected,
            reactionsCount: selected
                ? story.reactionsCount > 0
                      ? story.reactionsCount - 1
                      : 0
                : story.reactionsCount + (story.myReaction == null ? 1 : 0),
          );
    });
  }

  Future<void> _sendReply() async {
    final story = _story;
    final message = _replyController.text.trim();
    if (story == null || message.isEmpty || _isSendingReply) {
      return;
    }

    setState(() => _isSendingReply = true);
    final provider = context.read<StoriesProvider>();
    final sent = await provider.replyToStory(story.id, message);

    if (!mounted) {
      return;
    }

    setState(() => _isSendingReply = false);
    if (!sent) {
      SnackbarHelper.showError(
        context,
        provider.errorMessage ?? 'Unable to send reply.',
      );
      return;
    }

    _replyController.clear();
    final updated = _storyFromProvider(story.id);
    setState(() {
      _story = updated ?? story.copyWith(repliesCount: story.repliesCount + 1);
    });
    SnackbarHelper.showSuccess(context, 'Reply sent.');
  }

  StoryModel? _storyFromProvider(int storyId) {
    for (final story in context.read<StoriesProvider>().stories) {
      if (story.id == storyId) {
        return story;
      }
    }

    return null;
  }

  Future<void> _confirmDelete() async {
    final story = _story;
    if (story == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete story?'),
        content: const Text('This story will be removed from SnapCircle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final deleted = await context.read<StoriesProvider>().deleteStory(story.id);
    if (!mounted) {
      return;
    }

    if (deleted) {
      SnackbarHelper.showSuccess(context, 'Story deleted.');
      context.pop();
      return;
    }

    SnackbarHelper.showError(
      context,
      context.read<StoriesProvider>().errorMessage ?? 'Unable to delete story.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody(story)),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _goToAdjacentStory(-1),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _goToAdjacentStory(1),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppSizes.paddingSmall,
              left: AppSizes.paddingSmall,
              right: AppSizes.paddingSmall,
              child: _StoryHeader(
                story: story,
                onClose: () => context.pop(),
                onDelete: story?.canDelete == true ? _confirmDelete : null,
              ),
            ),
            if (story != null)
              Positioned(
                left: AppSizes.paddingSmall,
                right: AppSizes.paddingSmall,
                bottom: AppSizes.paddingSmall,
                child: _StoryActions(
                  story: story,
                  controller: _replyController,
                  isSendingReply: _isSendingReply,
                  onReaction: _toggleReaction,
                  onSendReply: _sendReply,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(StoryModel? story) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading story...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: ErrorView(
            message: _errorMessage!,
            onRetry: _loadStoryIfNeeded,
          ),
        ),
      );
    }

    if (story == null || story.mediaUrl == null) {
      return const Center(
        child: Text(
          'Story not available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: story.mediaUrl!,
          fit: BoxFit.contain,
          placeholder: (_, _) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white),
          ),
        ),
        if (story.caption != null && story.caption!.trim().isNotEmpty)
          Positioned(
            left: AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
            bottom: 128,
            child: Text(
              story.caption!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                shadows: const [Shadow(blurRadius: 8)],
              ),
            ),
          ),
      ],
    );
  }
}

class _StoryHeader extends StatelessWidget {
  final StoryModel? story;
  final VoidCallback onClose;
  final VoidCallback? onDelete;

  const _StoryHeader({
    required this.story,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(
          name: story?.user.name ?? 'Story',
          imageUrl: story?.user.avatar,
          size: AppAvatarSize.small,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story?.user.name ?? 'Story',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                story == null
                    ? ''
                    : '${DateFormatter.timeAgo(story?.createdAt)} - expires in 24h',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete story',
          ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: Colors.white),
          tooltip: 'Close story',
        ),
      ],
    );
  }
}

class _StoryActions extends StatelessWidget {
  final StoryModel story;
  final TextEditingController controller;
  final bool isSendingReply;
  final ValueChanged<String> onReaction;
  final VoidCallback onSendReply;

  const _StoryActions({
    required this.story,
    required this.controller,
    required this.isSendingReply,
    required this.onReaction,
    required this.onSendReply,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ReactionButton(
                    icon: Icons.thumb_up_alt_outlined,
                    selectedIcon: Icons.thumb_up_alt,
                    reaction: 'like',
                    selectedReaction: story.myReaction,
                    onTap: onReaction,
                  ),
                ),
                Expanded(
                  child: _ReactionButton(
                    icon: Icons.favorite_border,
                    selectedIcon: Icons.favorite,
                    reaction: 'love',
                    selectedReaction: story.myReaction,
                    onTap: onReaction,
                  ),
                ),
                Expanded(
                  child: _ReactionButton(
                    icon: Icons.sentiment_very_satisfied_outlined,
                    selectedIcon: Icons.sentiment_very_satisfied,
                    reaction: 'laugh',
                    selectedReaction: story.myReaction,
                    onTap: onReaction,
                  ),
                ),
                Expanded(
                  child: _ReactionButton(
                    icon: Icons.local_fire_department_outlined,
                    selectedIcon: Icons.local_fire_department,
                    reaction: 'fire',
                    selectedReaction: story.myReaction,
                    onTap: onReaction,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '${story.reactionsCount}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isSendingReply,
                    minLines: 1,
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSendReply(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Reply to ${story.user.name}',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isSendingReply ? null : onSendReply,
                  icon: isSendingReply
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  tooltip: 'Send reply',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String reaction;
  final String? selectedReaction;
  final ValueChanged<String> onTap;

  const _ReactionButton({
    required this.icon,
    required this.selectedIcon,
    required this.reaction,
    required this.selectedReaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedReaction == reaction;

    return IconButton(
      onPressed: () => onTap(reaction),
      icon: Icon(selected ? selectedIcon : icon),
      color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
      tooltip: selected ? 'Remove $reaction reaction' : 'React $reaction',
      visualDensity: VisualDensity.compact,
    );
  }
}
