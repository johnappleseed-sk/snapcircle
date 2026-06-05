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
  StoryModel? _story;
  bool _isLoading = false;
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
            bottom: AppSizes.paddingLarge,
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
