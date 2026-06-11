import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _selectedAvatar;
  XFile? _selectedCover;
  bool _isPrivate = false;
  bool _initialized = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initializeFields(ProfileProvider profileProvider) {
    if (_initialized || profileProvider.profile == null) {
      return;
    }

    final profile = profileProvider.profile!;
    _nameController.text = profile.name;
    _usernameController.text = profile.username ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _websiteController.text = profile.website ?? '';
    _isPrivate = profile.isPrivate;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final pickedImage = await _pickImage();
    if (pickedImage != null) {
      setState(() {
        _selectedAvatar = pickedImage;
        _localError = null;
      });
    }
  }

  Future<void> _pickCover() async {
    final pickedImage = await _pickImage();
    if (pickedImage != null) {
      setState(() {
        _selectedCover = pickedImage;
        _localError = null;
      });
    }
  }

  Future<XFile?> _pickImage() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    final updatedProfile = await profileProvider.updateProfile(
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      location: _locationController.text,
      website: _websiteController.text,
      avatar: _selectedAvatar,
      coverImage: _selectedCover,
      isPrivate: _isPrivate,
    );

    if (!mounted) {
      return;
    }

    if (updatedProfile != null) {
      context.read<AuthProvider>().updateUser(updatedProfile);
      SnackbarHelper.showSuccess(context, 'Profile updated successfully.');
      context.pop();
      return;
    }

    setState(() {
      _localError = profileProvider.errorMessage ?? 'Unable to update profile.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    _initializeFields(profileProvider);
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: profile == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.paddingMedium,
                    AppSizes.paddingMedium,
                    AppSizes.paddingMedium,
                    AppSizes.paddingLarge +
                        MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _CoverPreview(
                            selectedCover: _selectedCover,
                            coverUrl: profile.coverImageUrl,
                            onPick: _pickCover,
                          ),
                          Transform.translate(
                            offset: const Offset(0, -36),
                            child: _AvatarPreview(
                              selectedAvatar: _selectedAvatar,
                              avatarUrl: profile.avatarUrl ?? profile.avatar,
                              onPick: _pickAvatar,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    AppTextField(
                      label: 'Name',
                      hint: 'Your name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Username',
                      hint: 'maya.sok',
                      controller: _usernameController,
                      validator: (value) {
                        final username = value?.trim() ?? '';
                        if (username.contains(' ')) {
                          return 'Username cannot contain spaces.';
                        }
                        if (username.isNotEmpty &&
                            !RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(username)) {
                          return 'Use letters, numbers, underscore, or dot.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Bio',
                      hint: 'Tell people about yourself',
                      controller: _bioController,
                      maxLines: 4,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_bioController.text.length}/500',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Location',
                      hint: 'Phnom Penh',
                      controller: _locationController,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Website',
                      hint: 'https://example.com',
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        final website = value?.trim() ?? '';
                        if (website.isEmpty) {
                          return null;
                        }
                        final uri = Uri.tryParse(website);
                        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                          return 'Enter a valid URL.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    SwitchListTile.adaptive(
                      value: _isPrivate,
                      onChanged: profileProvider.isUpdating
                          ? null
                          : (value) => setState(() => _isPrivate = value),
                      title: const Text('Private profile'),
                      subtitle: const Text(
                        'Limit discovery and follow access when supported.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_localError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _localError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.paddingLarge),
                    AppButton(
                      label: 'Save Profile',
                      icon: Icons.save_outlined,
                      isLoading: profileProvider.isUpdating,
                      onPressed: profileProvider.isUpdating ? null : _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  final XFile? selectedCover;
  final String? coverUrl;
  final VoidCallback onPick;

  const _CoverPreview({
    required this.selectedCover,
    required this.coverUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusMedium),
          ),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: selectedCover != null
                ? _PickedImage(image: selectedCover!, fit: BoxFit.cover)
                : coverUrl != null && coverUrl!.isNotEmpty
                ? CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                          AppColors.accent.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Cover'),
          ),
        ),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final XFile? selectedAvatar;
  final String? avatarUrl;
  final VoidCallback onPick;

  const _AvatarPreview({
    required this.selectedAvatar,
    required this.avatarUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: SizedBox(
              height: 108,
              width: 108,
              child: selectedAvatar != null
                  ? _PickedImage(image: selectedAvatar!, fit: BoxFit.cover)
                  : avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: avatarUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 54),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton.filled(
            onPressed: onPick,
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Change avatar',
          ),
        ),
      ],
    );
  }
}

class _PickedImage extends StatelessWidget {
  final XFile image;
  final BoxFit fit;

  const _PickedImage({required this.image, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return Image.memory(snapshot.data!, fit: fit);
        },
      );
    }

    return Image.file(File(image.path), fit: fit);
  }
}
