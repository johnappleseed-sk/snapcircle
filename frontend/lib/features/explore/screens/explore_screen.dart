import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../providers/explore_provider.dart';
import '../widgets/explore_post_grid_item.dart';
import '../widgets/explore_search_bar.dart';
import '../widgets/recommended_user_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExploreProvider>();
      if (provider.explorePosts.isEmpty) {
        provider.fetchExploreData(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchExploreData(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingXL,
          ),
          children: [
            ExploreSearchBar(
              query: provider.searchQuery,
              onSearch: provider.searchExplore,
              onClear: provider.clearSearch,
            ),
            if (provider.searchQuery.isEmpty &&
                provider.recentSearches.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              _RecentSearchesSection(provider: provider),
            ],
            const SizedBox(height: AppSizes.paddingMedium),
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
                _RecommendedUsersSection(provider: provider),
                const SizedBox(height: AppSizes.paddingLarge),
                _TrendingPostsSection(provider: provider),
                const SizedBox(height: AppSizes.paddingLarge),
              ],
              _ExplorePostsSection(provider: provider),
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
            itemBuilder: (context, index) => const SizedBox(
              width: 150,
              child: SkeletonBox(height: 188),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.paddingSmall,
            mainAxisSpacing: AppSizes.paddingSmall,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) => const SkeletonBox(height: 180),
        ),
      ],
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
            color: AppColors.textSecondary,
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

class _RecommendedUsersSection extends StatelessWidget {
  final ExploreProvider provider;

  const _RecommendedUsersSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.recommendedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended people',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: 238,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending now',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.trendingPosts.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSizes.paddingSmall),
            itemBuilder: (context, index) {
              final post = provider.trendingPosts[index];
              return SizedBox(
                width: 150,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                provider.searchQuery.isEmpty ? 'Explore posts' : 'Posts',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            if (provider.searchQuery.isEmpty)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'latest', label: Text('Latest')),
                  ButtonSegment(value: 'popular', label: Text('Popular')),
                ],
                selected: {provider.currentSort},
                onSelectionChanged: (values) =>
                    provider.changeSort(values.first),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        if (posts.isEmpty)
          const EmptyView(
            icon: Icons.travel_explore_outlined,
            title: 'Nothing to discover yet',
            subtitle: 'Try another search or check back after more posts.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.paddingSmall,
              mainAxisSpacing: AppSizes.paddingSmall,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final post = posts[index];
              return ExplorePostGridItem(
                post: post,
                onTap: () => context.push('/posts/${post.id}', extra: post),
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
}
