import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        children: [
          _CreateOption(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Create Post',
            subtitle: 'Share a photo, thought, or update with your circle.',
            onTap: () => context.push('/create-post'),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _CreateOption(
            icon: Icons.auto_stories_outlined,
            title: 'Create Story',
            subtitle: 'Post a lightweight story that expires after 24 hours.',
            onTap: () => context.push('/stories/create'),
          ),
        ],
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 34),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
