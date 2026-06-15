import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_box.dart';

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
          SkeletonBox(height: 170),
          SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              _SkeletonFixedLine(width: 54),
              SizedBox(width: AppSizes.paddingLarge),
              _SkeletonFixedLine(width: 54),
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
    return SkeletonBox(
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(999),
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
      child: const SkeletonBox(height: 12),
    );
  }
}

class _SkeletonFixedLine extends StatelessWidget {
  final double width;

  const _SkeletonFixedLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(height: 12, width: width);
  }
}
