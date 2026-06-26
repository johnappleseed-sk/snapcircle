import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_masonry_grid.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../providers/explore_provider.dart';
import '../widgets/explore_post_grid_item.dart';
import '../widgets/explore_search_bar.dart';
import '../widgets/recommended_user_card.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialTag;

  const ExploreScreen({super.key, this.initialTag});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialContent();
    });
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTag != widget.initialTag) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialContent();
      });
    }
  }

  void _loadInitialContent() {
    final provider = context.read<ExploreProvider>();
    final initialTag = widget.initialTag?.trim();

    if (initialTag != null && initialTag.isNotEmpty) {
      provider.openTag(initialTag);
      return;
    }

    if (provider.explorePosts.isEmpty) {
      provider.fetchExploreData(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            onPressed: () => provider.fetchExploreData(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh discovery',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchExploreData(refresh: true),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          children: [
            ExploreSearchBar(
              query: provider.searchQuery,
              onSearch: provider.searchExplore,
              onClear: provider.clearSearch,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _DiscoveryTopics(provider: provider),
            if (provider.searchQuery.isEmpty &&
                provider.recentSearches.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              _RecentSearchesSection(provider: provider),
            ],
            const SizedBox(height: AppSizes.paddingMedium),
            if (provider.searchQuery.isEmpty) ...[
              _DiscoverySummary(provider: provider),
              const SizedBox(height: AppSizes.paddingMedium),
            ],
            if (provider.isLoading && provider.explorePosts.isEmpty)
              const _ExploreSkeleton()
            else if (provider.errorMessage != null &&
                provider.explorePosts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 72),
                child: ErrorView(
                  message: provider.errorMessage!,
                  onRetry: () => provider.fetchExploreData(refresh: true),
                ),
              )
            else ...[
              if (provider.searchQuery.isNotEmpty)
                _SearchResults(provider: provider)
              else ...[
                _TrendingTagsSection(provider: provider),
                if (provider.trendingTags.isNotEmpty)
                  const SizedBox(height: AppSizes.paddingLarge),
                _RecommendedUsersSection(provider: provider),
                const SizedBox(height: AppSizes.paddingLarge),
                _TrendingPostsSection(provider: provider),
                const SizedBox(height: AppSizes.paddingMedium),
              ],
              _ExplorePostsSection(provider: provider),
              const SizedBox(height: 88),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) =>
                const SizedBox(width: 150, child: SkeletonBox(height: 188)),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        AppMasonryGrid(
          itemCount: 4,
          itemBuilder: (context, index) =>
              SkeletonBox(height: index.isEven ? 210 : 168),
        ),
      ],
    );
  }
}

class _DiscoveryTopics extends StatelessWidget {
  final ExploreProvider provider;

  const _DiscoveryTopics({required this.provider});

  static const _topics = [
    ('For You', Icons.auto_awesome_rounded, null),
    ('Food', Icons.restaurant_outlined, 'food'),
    ('Style', Icons.checkroom_outlined, 'style'),
    ('Travel', Icons.flight_takeoff_rounded, 'travel'),
    ('Home', Icons.chair_outlined, 'home'),
    ('Fitness', Icons.fitness_center_rounded, 'fitness'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          final tag = topic.$3;
          final selected =
              (tag == null && provider.selectedTag == null) ||
              provider.selectedTag == tag;
          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              topic.$2,
              size: 17,
              color: selected ? Colors.white : AppColors.primary,
            ),
            label: Text(topic.$1),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : theme.dividerColor,
            ),
            onSelected: (_) {
              if (tag == null) {
                provider.clearSearch();
              } else {
                provider.selectTagName(tag);
              }
            },
          );
        },
      ),
    );
  }
}

class _DiscoverySummary extends StatelessWidget {
  final ExploreProvider provider;

  const _DiscoverySummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTag = provider.selectedTag;
    final hasActiveTag = activeTag != null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.20 : 0.055,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Icon(
                  hasActiveTag
                      ? Icons.tag_rounded
                      : Icons.travel_explore_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActiveTag ? '#$activeTag' : 'Discovery is live',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasActiveTag
                          ? 'Browsing posts with this tag'
                          : 'Fresh posts, topics, and people to follow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.62,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveTag)
                IconButton.filledTonal(
                  onPressed: provider.clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear tag',
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _DiscoveryMetric(
                  icon: Icons.grid_view_rounded,
                  label: 'Posts',
                  value: _compactCount(provider.explorePosts.length),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: _DiscoveryMetric(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Trending',
                  value: _compactCount(provider.trendingPosts.length),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: _DiscoveryMetric(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'People',
                  value: _compactCount(provider.recommendedUsers.length),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _compactCount(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _DiscoveryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DiscoveryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.30 : 0.58,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchesSection extends StatelessWidget {
  final ExploreProvider provider;

  const _RecentSearchesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Recent',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.64),
            fontWeight: FontWeight.w800,
          ),
        ),
        for (final query in provider.recentSearches)
          ActionChip(
            avatar: const Icon(Icons.history, size: 16),
            label: Text(query),
            onPressed: () => provider.searchExplore(query),
          ),
        TextButton(
          onPressed: provider.clearRecentSearches,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _TrendingTagsSection extends StatelessWidget {
  final ExploreProvider provider;

  const _TrendingTagsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.trendingTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending tags'),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.trendingTags.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              final tag = provider.trendingTags[index];
              final isSelected = provider.selectedTag == tag.tag;

              return ChoiceChip(
                selected: isSelected,
                avatar: Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                label: Text('${tag.label} ${tag.postsCount}'),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : theme.dividerColor,
                ),
                onSelected: (_) => provider.selectTag(tag),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendedUsersSection extends StatelessWidget {
  final ExploreProvider provider;

  const _RecommendedUsersSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.recommendedUsers.isEmpty) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 360 ? 154.0 : 170.0;
    final cardHeight = screenWidth < 360 ? 256.0 : 268.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recommended people'),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.recommendedUsers.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              final user = provider.recommendedUsers[index];
              return RecommendedUserCard(
                user: user,
                isUpdating: provider.isFollowingUser(user.id),
                width: cardWidth,
                onTap: () => context.push('/users/${user.id}'),
                onFollowTap: () => provider.toggleFollow(user),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingPostsSection extends StatelessWidget {
  final ExploreProvider provider;

  const _TrendingPostsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.trendingPosts.isEmpty) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = screenWidth < 360 ? 136.0 : 150.0;
    final tileHeight = screenWidth < 360 ? 172.0 : 188.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending now'),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.trendingPosts.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              final post = provider.trendingPosts[index];
              return SizedBox(
                width: tileWidth,
                child: ExplorePostGridItem(
                  post: post,
                  onTap: () => context.push('/posts/${post.id}', extra: post),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final ExploreProvider provider;

  const _SearchResults({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isSearching) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: LoadingView(message: 'Searching SnapCircle...'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.exploreUsers.isNotEmpty) ...[
          Text(
            'People',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          for (final user in provider.exploreUsers) ...[
            RecommendedUserCard(
              user: user,
              isUpdating: provider.isFollowingUser(user.id),
              width: double.infinity,
              onTap: () => context.push('/users/${user.id}'),
              onFollowTap: () => provider.toggleFollow(user),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
        ],
      ],
    );
  }
}

class _ExplorePostsSection extends StatelessWidget {
  final ExploreProvider provider;

  const _ExplorePostsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final posts = provider.explorePosts;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExplorePostsHeader(provider: provider, isCompact: isCompact),
        const SizedBox(height: AppSizes.paddingSmall),
        if (posts.isEmpty)
          const EmptyView(
            icon: Icons.travel_explore_outlined,
            title: 'Nothing to discover yet',
            subtitle: 'Try another search or check back after more posts.',
          )
        else
          AppMasonryGrid(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return SizedBox(
                height: _tileHeight(post.id),
                child: ExplorePostGridItem(
                  post: post,
                  onTap: () => context.push('/posts/${post.id}', extra: post),
                ),
              );
            },
          ),
        if (provider.hasMorePosts && provider.searchQuery.isEmpty) ...[
          const SizedBox(height: AppSizes.paddingMedium),
          AppButton(
            label: 'Load more',
            variant: AppButtonVariant.outline,
            isLoading: provider.isLoadingMore,
            onPressed: provider.isLoadingMore ? null : provider.loadMorePosts,
          ),
        ],
        if (provider.errorMessage != null && posts.isNotEmpty) ...[
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            provider.errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  double _tileHeight(int postId) {
    return switch (postId % 5) {
      0 => 260,
      1 => 214,
      2 => 238,
      3 => 188,
      _ => 230,
    };
  }
}

class _ExplorePostsHeader extends StatelessWidget {
  final ExploreProvider provider;
  final bool isCompact;

  const _ExplorePostsHeader({required this.provider, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final title = provider.selectedTag == null
        ? provider.searchQuery.isEmpty
              ? 'Explore posts'
              : 'Posts'
        : '#${provider.selectedTag} posts';
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
    final clearChip = provider.selectedTag == null
        ? null
        : ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Clear tag'),
            onPressed: provider.clearSearch,
          );
    final sortControl = provider.searchQuery.isNotEmpty
        ? null
        : SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'latest', label: Text('Latest')),
              ButtonSegment(value: 'popular', label: Text('Popular')),
            ],
            selected: {provider.currentSort},
            onSelectionChanged: (values) => provider.changeSort(values.first),
          );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          if (clearChip != null) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            clearChip,
          ],
          if (sortControl != null) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            SizedBox(width: double.infinity, child: sortControl),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleWidget),
        if (clearChip != null) ...[
          const SizedBox(width: AppSizes.paddingSmall),
          clearChip,
        ],
        if (sortControl != null) ...[
          const SizedBox(width: AppSizes.paddingSmall),
          sortControl,
        ],
      ],
    );
  }
}
