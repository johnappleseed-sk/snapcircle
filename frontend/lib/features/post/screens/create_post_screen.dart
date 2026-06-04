import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully.')),
      );
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
      appBar: AppBar(title: const Text('Create Post')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'What is happening?',
              hint: 'Share something with your circle...',
              controller: _contentController,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            if (_selectedImage == null)
              OutlinedButton.icon(
                onPressed: feedProvider.isCreating ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose image'),
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
            if (_localError != null) ...[
              const SizedBox(height: 14),
              _CreatePostError(message: _localError!),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Post',
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

class _SelectedImagePreview extends StatelessWidget {
  final File image;
  final VoidCallback? onRemove;

  const _SelectedImagePreview({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
