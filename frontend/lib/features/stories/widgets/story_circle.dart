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
    final ringGradient = isViewed
        ? null
        : const LinearGradient(
            colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return SizedBox(
      width: 68,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ringGradient,
                border: ringGradient == null
                    ? Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 2,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: SizedBox.expand(
                        child: imageUrl == null
                            ? Container(
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported),
                                ),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
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
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
