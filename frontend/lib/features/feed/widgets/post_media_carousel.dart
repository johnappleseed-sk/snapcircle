import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/post_model.dart';

class PostMediaCarousel extends StatefulWidget {
  final List<PostMediaModel> media;
  final double aspectRatio;

  const PostMediaCarousel({
    super.key,
    required this.media,
    this.aspectRatio = 4 / 3,
  });

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media.where((item) => item.url.isNotEmpty).toList();
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageFill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final mediaCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: PageView.builder(
              controller: _pageController,
              itemCount: media.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: media[index].url,
                  fit: BoxFit.cover,
                  memCacheWidth: mediaCacheWidth,
                  placeholder: (context, url) => Container(
                    color: imageFill,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: imageFill,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (media.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(media.length, (index) {
              final selected = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: selected ? 18 : 6,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.mutedText.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
