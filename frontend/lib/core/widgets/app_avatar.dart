import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum AppAvatarSize { small, medium, large }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final AppAvatarSize size;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = AppAvatarSize.medium,
  });

  double get _dimension {
    return switch (size) {
      AppAvatarSize.small => AppSizes.avatarSizeSmall,
      AppAvatarSize.medium => AppSizes.avatarSizeMedium,
      AppAvatarSize.large => AppSizes.avatarSizeLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.characters.first.toUpperCase())
            .join();

    final fallback = Container(
      height: _dimension,
      width: _dimension,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w900,
          fontSize: _dimension * 0.34,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        height: _dimension,
        width: _dimension,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}
