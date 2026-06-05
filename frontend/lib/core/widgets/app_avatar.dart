import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum AppAvatarSize { small, medium, large, extraLarge }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final AppAvatarSize size;
  final bool showBorder;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = AppAvatarSize.medium,
    this.showBorder = false,
  });

  double get _dimension {
    return switch (size) {
      AppAvatarSize.small => AppSizes.avatarSmall,
      AppAvatarSize.medium => AppSizes.avatarMedium,
      AppAvatarSize.large => AppSizes.avatarLarge,
      AppAvatarSize.extraLarge => AppSizes.avatarXL,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      dimension: _dimension,
      initials: _initials,
      showBorder: showBorder,
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }

    return Container(
      height: _dimension,
      width: _dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.surface, width: 3)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }
}

class _AvatarFallback extends StatelessWidget {
  final double dimension;
  final String initials;
  final bool showBorder;

  const _AvatarFallback({
    required this.dimension,
    required this.initials,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dimension,
      width: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.surface, width: 3)
            : null,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w900,
          fontSize: dimension * 0.34,
        ),
      ),
    );
  }
}
