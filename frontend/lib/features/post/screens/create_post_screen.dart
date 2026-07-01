import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../feed/models/post_model.dart';
import '../../feed/providers/feed_provider.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? initialPost;

  const CreatePostScreen({super.key, this.initialPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _maxPostLength = 1000;
  static const _maxImages = 10;

  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  String? _localError;
  bool get _isEditing => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.initialPost?.content ?? '';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedImages = await _imagePicker.pickMultiImage(imageQuality: 85);

    if (pickedImages.isEmpty) {
      return;
    }

    final nextImages = [
      ..._selectedImages,
      ...pickedImages.map((image) => File(image.path)),
    ];

    if (nextImages.length > _maxImages) {
      setState(() {
        _localError = 'Choose up to $_maxImages images for one post.';
      });
      return;
    }

    setState(() {
      _selectedImages
        ..clear()
        ..addAll(nextImages);
      _localError = null;
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    final hasExistingImage =
        _isEditing && widget.initialPost?.media.isNotEmpty == true;

    if (content.isEmpty && _selectedImages.isEmpty && !hasExistingImage) {
      setState(() {
        _localError = 'Add some text or choose an image before posting.';
      });
      return;
    }

    if (content.length > _maxPostLength) {
      setState(() {
        _localError = 'Posts can be up to $_maxPostLength characters.';
      });
      return;
    }

    final feedProvider = context.read<FeedProvider>();
    final updatedPost = _isEditing
        ? await feedProvider.updatePost(
            widget.initialPost!.id,
            content: content,
            images: _selectedImages,
          )
        : null;
    final created = _isEditing
        ? updatedPost != null
        : await feedProvider.createPost(
            content: content,
            images: _selectedImages,
          );

    if (!mounted) {
      return;
    }

    if (created) {
      SnackbarHelper.showSuccess(
        context,
        _isEditing
            ? 'Post updated successfully.'
            : 'Post created successfully.',
      );
      if (_isEditing) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }

    setState(() {
      _localError = feedProvider.errorMessage ?? 'Unable to create post.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final contentLength = _contentController.text.trim().length;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;
    final hasExistingImage =
        _isEditing && widget.initialPost?.media.isNotEmpty == true;
    final canSubmit =
        !feedProvider.isCreating &&
        (_selectedImages.isNotEmpty || hasExistingImage || contentLength > 0) &&
        contentLength <= _maxPostLength;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: feedProvider.isCreating ? null : _pickImages,
          icon: const Icon(Icons.camera_alt_outlined),
          tooltip: 'Choose media',
        ),
        title: const Text('SnapCircle'),
        actions: [
          IconButton(
            onPressed: canSubmit ? _submitPost : null,
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.send_outlined),
            tooltip: _isEditing ? 'Save changes' : 'Share post',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingLarge + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Text(
              _isEditing ? 'Edit Post' : 'Create Post',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedImages.isEmpty)
                  _ImagePickerArea(
                    isDisabled: feedProvider.isCreating,
                    onPick: _pickImages,
                    existingImageUrls: widget.initialPost?.media
                        .map((item) => item.url)
                        .toList(),
                  )
                else
                  _SelectedImagePreviewGrid(
                    images: _selectedImages,
                    onAdd: _selectedImages.length >= _maxImages
                        ? null
                        : _pickImages,
                    onRemove: feedProvider.isCreating
                        ? null
                        : (index) {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                  ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppTextField(
                  label: 'Caption',
                  hint: 'Write a caption...',
                  controller: _contentController,
                  enabled: !feedProvider.isCreating,
                  maxLines: 5,
                  onChanged: (_) {
                    if (_localError != null) {
                      setState(() => _localError = null);
                      return;
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$contentLength / $_maxPostLength',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: contentLength > _maxPostLength
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_localError != null) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _CreatePostError(message: _localError!),
            ],
            const SizedBox(height: AppSizes.paddingLarge),
            AppButton(
              label: _isEditing ? 'Save changes' : 'Share Post',
              icon: _isEditing ? Icons.save_outlined : Icons.send_outlined,
              isLoading: feedProvider.isCreating,
              onPressed: canSubmit ? _submitPost : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onPick;
  final List<String>? existingImageUrls;

  const _ImagePickerArea({
    required this.isDisabled,
    required this.onPick,
    this.existingImageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final existingImages =
        existingImageUrls?.where((url) => url.isNotEmpty).toList() ??
        const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (existingImages.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: PageView.builder(
                itemCount: existingImages.length,
                itemBuilder: (context, index) {
                  final devicePixelRatio = MediaQuery.devicePixelRatioOf(
                    context,
                  ).clamp(1.0, 2.25);
                  final cacheWidth =
                      (MediaQuery.sizeOf(context).width * devicePixelRatio)
                          .round()
                          .clamp(480, 1080);
                  return CachedNetworkImage(
                    imageUrl: existingImages[index],
                    fit: BoxFit.cover,
                    memCacheWidth: cacheWidth,
                    memCacheHeight: (cacheWidth / (4 / 3)).round(),
                    placeholder: (context, url) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
        ],
        OutlinedButton(
          onPressed: isDisabled ? null : onPick,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.border, width: 1.4),
            backgroundColor: AppColors.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 88),
            child: Column(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  existingImages.isEmpty ? 'Upload Media' : 'Replace Media',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tap to browse photos or videos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedImagePreviewGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  const _SelectedImagePreviewGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 360 ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _LocalImagePreview(image: images[index], fit: BoxFit.cover),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove == null
                          ? null
                          : () => onRemove!(index),
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Remove image',
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text('Add more (${images.length}/10)'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
      ],
    );
  }
}

class _LocalImagePreview extends StatelessWidget {
  final File image;
  final BoxFit fit;

  const _LocalImagePreview({required this.image, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.file(image, fit: fit);
    }

    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return Image.memory(snapshot.data!, fit: fit);
      },
    );
  }
}

class _CreatePostError extends StatelessWidget {
  final String message;

  const _CreatePostError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
