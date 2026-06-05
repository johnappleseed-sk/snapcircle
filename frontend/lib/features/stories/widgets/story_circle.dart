import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class StoryCircle extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isViewed;
  final bool isAddItem;
  final VoidCallback onTap;

  const StoryCircle({
    super.key,
    required this.label,
    required this.onTap,
    this.imageUrl,
    this.isViewed = false,
    this.isAddItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isAddItem
        ? AppColors.primary
        : isViewed
        ? AppColors.border
        : AppColors.primary;

    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Stack(
                children: [
                  ClipOval(
                    child: SizedBox.expand(
                      child: imageUrl == null
                          ? Container(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  Container(color: AppColors.border),
                              errorWidget: (_, _, _) => Container(
                                color: AppColors.border,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                    ),
                  ),
                  if (isAddItem)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
