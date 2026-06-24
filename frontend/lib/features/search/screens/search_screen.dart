import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/users_provider.dart';
import '../widgets/user_skeleton_tile.dart';
import '../widgets/user_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchUsers(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<UsersProvider>().fetchUsers(
        refresh: true,
        search: value.trim().isEmpty ? null : value.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: RefreshIndicator(
        onRefresh: () => usersProvider.fetchUsers(
          refresh: true,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingXL,
          ),
          children: [
            AppTextField(
              label: 'Search SnapCircle',
              hint: 'Creators, friends, interests',
              controller: _searchController,
              onChanged: _onSearchChanged,
              prefixIcon: const Icon(Icons.search_outlined),
            ),
            const SizedBox(height: 12),
            _SearchDiscovery(
              onSelect: (query) {
                _searchController.text = query;
                _onSearchChanged(query);
              },
            ),
            const SizedBox(height: 16),
            _SearchResults(usersProvider: usersProvider),
          ],
        ),
      ),
    );
  }
}

class _SearchDiscovery extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _SearchDiscovery({required this.onSelect});

  static const _recent = ['design', 'travel', 'food', 'fitness'];
  static const _trending = ['creator tips', 'weekend finds', 'home cafe'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover faster',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _recent)
                ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  label: Text(item),
                  onPressed: () => onSelect(item),
                ),
              for (final item in _trending)
                ActionChip(
                  avatar: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(item),
                  onPressed: () => onSelect(item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final UsersProvider usersProvider;

  const _SearchResults({required this.usersProvider});

  @override
  Widget build(BuildContext context) {
    if (usersProvider.isLoading && usersProvider.users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Column(
          children: [
            UserSkeletonTile(),
            SizedBox(height: 12),
            UserSkeletonTile(),
            SizedBox(height: 12),
            UserSkeletonTile(),
          ],
        ),
      );
    }

    if (usersProvider.errorMessage != null && usersProvider.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 72),
        child: ErrorView(
          message: usersProvider.errorMessage!,
          onRetry: () => usersProvider.fetchUsers(refresh: true),
        ),
      );
    }

    if (usersProvider.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 72),
        child: const EmptyView(
          icon: Icons.search_off_outlined,
          title: 'No users found',
          subtitle: 'Try another name, email, or profile keyword.',
        ),
      );
    }

    return Column(
      children: [
        for (final user in usersProvider.users) ...[
          UserTile(user: user, onTap: () => context.push('/users/${user.id}')),
          const SizedBox(height: 12),
        ],
        if (usersProvider.hasMore)
          AppButton(
            label: 'Load more',
            variant: AppButtonVariant.outline,
            onPressed: usersProvider.isLoadingMore
                ? null
                : usersProvider.loadMoreUsers,
            isLoading: usersProvider.isLoadingMore,
          ),
      ],
    );
  }
}
