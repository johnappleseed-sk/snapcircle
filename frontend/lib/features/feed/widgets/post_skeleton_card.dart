import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';

class PostSkeletonCard extends StatelessWidget {
  const PostSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonCircle(size: AppSizes.avatarMedium),
              SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(widthFactor: 0.55),
                    SizedBox(height: AppSizes.paddingSmall),
                    _SkeletonLine(widthFactor: 0.32),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.paddingLarge),
          _SkeletonLine(widthFactor: 0.92),
          SizedBox(height: AppSizes.paddingSmall),
          _SkeletonLine(widthFactor: 0.72),
          SizedBox(height: AppSizes.paddingMedium),
          _SkeletonBox(height: 170),
          SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              _SkeletonLine(widthFactor: 0.14),
              SizedBox(width: AppSizes.paddingLarge),
              _SkeletonLine(widthFactor: 0.14),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _SkeletonLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: const _SkeletonBox(height: 12),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
    );
  }
}
