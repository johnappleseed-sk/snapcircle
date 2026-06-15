import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/hashtag_utils.dart';

class HashtagCaption extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTagTap;

  const HashtagCaption({super.key, required this.text, required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    final caption = HashtagUtils.strip(text);
    final tags = HashtagUtils.extract(text);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption.isNotEmpty)
          Text(
            caption,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        if (tags.isNotEmpty) ...[
          if (caption.isNotEmpty) const SizedBox(height: AppSizes.paddingSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                ActionChip(
                  avatar: const Icon(Icons.tag_rounded, size: 16),
                  label: Text('#$tag'),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                  onPressed: () => onTagTap(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
