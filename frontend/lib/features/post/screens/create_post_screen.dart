import 'dart:io';

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
import '../../feed/providers/feed_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _localError;

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

    if (content.isEmpty && _selectedImage == null) {
      setState(() {
        _localError = 'Add some text or choose an image before posting.';
      });
      return;
    }

    final feedProvider = context.read<FeedProvider>();
    final created = await feedProvider.createPost(
      content: content,
      image: _selectedImage,
    );

    if (!mounted) {
      return;
    }

    if (created) {
      SnackbarHelper.showSuccess(context, 'Post created successfully.');
      context.go('/home');
      return;
    }

    setState(() {
      _localError = feedProvider.errorMessage ?? 'Unable to create post.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create post'),
        actions: [
          TextButton(
            onPressed: feedProvider.isCreating ? null : _submitPost,
            child: const Text('Post'),
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
                    maxLines: 6,
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  if (_selectedImage == null)
                    _ImagePickerArea(
                      isDisabled: feedProvider.isCreating,
                      onPick: _pickImage,
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
              label: 'Share post',
              icon: Icons.send_outlined,
              isLoading: feedProvider.isCreating,
              onPressed: _submitPost,
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

  const _ImagePickerArea({required this.isDisabled, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isDisabled ? null : onPick,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 32),
            SizedBox(height: AppSizes.paddingSmall),
            Text('Add image'),
          ],
        ),
      ),
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
