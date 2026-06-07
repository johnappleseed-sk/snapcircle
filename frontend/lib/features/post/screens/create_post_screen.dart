import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
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

  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
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

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedImage = File(pickedImage.path);
      _localError = null;
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    final hasExistingImage =
        _isEditing && widget.initialPost?.imageUrl?.isNotEmpty == true;

    if (content.isEmpty && _selectedImage == null && !hasExistingImage) {
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
            image: _selectedImage,
          )
        : null;
    final created = _isEditing
        ? updatedPost != null
        : await feedProvider.createPost(content: content, image: _selectedImage);

    if (!mounted) {
      return;
    }

    if (created) {
      SnackbarHelper.showSuccess(
        context,
        _isEditing ? 'Post updated successfully.' : 'Post created successfully.',
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
    final hasExistingImage =
        _isEditing && widget.initialPost?.imageUrl?.isNotEmpty == true;
    final canSubmit =
        !feedProvider.isCreating &&
        (_selectedImage != null || hasExistingImage || contentLength > 0) &&
        contentLength <= _maxPostLength;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit post' : 'Create post'),
        actions: [
          TextButton(
            onPressed: canSubmit ? _submitPost : null,
            child: Text(_isEditing ? 'Save' : 'Post'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'What is happening?',
                    hint: 'Share something with your circle...',
                    controller: _contentController,
                    enabled: !feedProvider.isCreating,
                    maxLines: 6,
                    prefixIcon: const Icon(Icons.edit_outlined),
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
                  const SizedBox(height: AppSizes.paddingMedium),
                  if (_selectedImage == null)
                    _ImagePickerArea(
                      isDisabled: feedProvider.isCreating,
                      onPick: _pickImage,
                      existingImageUrl: widget.initialPost?.imageUrl,
                    )
                  else
                    _SelectedImagePreview(
                      image: _selectedImage!,
                      onRemove: feedProvider.isCreating
                          ? null
                          : () {
                              setState(() => _selectedImage = null);
                            },
                    ),
                ],
              ),
            ),
            if (_localError != null) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _CreatePostError(message: _localError!),
            ],
            const SizedBox(height: AppSizes.paddingLarge),
            AppButton(
              label: _isEditing ? 'Save changes' : 'Share post',
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
  final String? existingImageUrl;

  const _ImagePickerArea({
    required this.isDisabled,
    required this.onPick,
    this.existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (existingImageUrl != null && existingImageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: existingImageUrl!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
        ],
        OutlinedButton(
          onPressed: isDisabled ? null : onPick,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingLarge,
            ),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 32),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(existingImageUrl == null ? 'Add image' : 'Replace image'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final File image;
  final VoidCallback? onRemove;

  const _SelectedImagePreview({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            tooltip: 'Remove image',
          ),
        ),
      ],
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
