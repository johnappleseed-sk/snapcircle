import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/stories_provider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _localError;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedImage = File(pickedImage.path);
      _localError = null;
    });
  }

  Future<void> _submitStory() async {
    final image = _selectedImage;
    if (image == null) {
      setState(() => _localError = 'Choose an image before sharing a story.');
      return;
    }

    final provider = context.read<StoriesProvider>();
    final created = await provider.createStory(
      media: image,
      caption: _captionController.text,
    );

    if (!mounted) {
      return;
    }

    if (created) {
      SnackbarHelper.showSuccess(context, 'Story shared successfully.');
      context.go('/home');
      return;
    }

    setState(() {
      _localError = provider.errorMessage ?? 'Unable to share story.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoriesProvider>();
    final canSubmit = !provider.isCreating && _selectedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create story'),
        actions: [
          TextButton(
            onPressed: canSubmit ? _submitStory : null,
            child: const Text('Share'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingLarge + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedImage == null)
                    OutlinedButton(
                      onPressed: provider.isCreating ? null : _pickImage,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSizes.paddingXL,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 34),
                            SizedBox(height: AppSizes.paddingSmall),
                            Text('Choose story image'),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            onPressed: provider.isCreating
                                ? null
                                : () => setState(() => _selectedImage = null),
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove image',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppTextField(
                    label: 'Caption',
                    hint: 'Add a short caption...',
                    controller: _captionController,
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.short_text_outlined),
                  ),
                ],
              ),
            ),
            if (_localError != null) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _StoryError(message: _localError!),
            ],
            const SizedBox(height: AppSizes.paddingLarge),
            AppButton(
              label: 'Share story',
              icon: Icons.auto_stories_outlined,
              isLoading: provider.isCreating,
              onPressed: canSubmit ? _submitStory : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryError extends StatelessWidget {
  final String message;

  const _StoryError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
