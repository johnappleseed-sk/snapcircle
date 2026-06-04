import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
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
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedAvatar;
  bool _initialized = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeFields(ProfileProvider profileProvider) {
    if (_initialized || profileProvider.profile == null) {
      return;
    }

    _nameController.text = profileProvider.profile!.name;
    _bioController.text = profileProvider.profile!.bio ?? '';
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedAvatar = File(pickedImage.path);
      _localError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    final updatedProfile = await profileProvider.updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
      avatar: _selectedAvatar,
    );

    if (!mounted) {
      return;
    }

    if (updatedProfile != null) {
      context.read<AuthProvider>().updateUser(updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          _EditableAvatar(
                            selectedAvatar: _selectedAvatar,
                            avatarUrl: profile.avatar,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              onPressed: profileProvider.isUpdating
                                  ? null
                                  : _pickAvatar,
                              icon: const Icon(Icons.camera_alt_outlined),
                              tooltip: 'Choose avatar',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                      label: 'Bio',
                      hint: 'Tell people about yourself',
                      controller: _bioController,
                      maxLines: 4,
                    ),
                    if (_localError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _localError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Save Profile',
                      icon: Icons.save_outlined,
                      isLoading: profileProvider.isUpdating,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  final File? selectedAvatar;
  final String? avatarUrl;

  const _EditableAvatar({
    required this.selectedAvatar,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedAvatar != null) {
      return CircleAvatar(
        radius: 54,
        backgroundImage: FileImage(selectedAvatar!),
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 54,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }

    return const CircleAvatar(radius: 54, child: Icon(Icons.person, size: 54));
  }
}
