import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/users_provider.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            AppTextField(
              label: 'Search users',
              hint: 'Find by name or email',
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            _SearchResults(usersProvider: usersProvider),
          ],
        ),
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
        padding: EdgeInsets.only(top: 96),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (usersProvider.errorMessage != null && usersProvider.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 72),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 12),
            Text(usersProvider.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => usersProvider.fetchUsers(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (usersProvider.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 72),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_outlined,
              color: AppColors.mutedText,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No users found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
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
          OutlinedButton(
            onPressed: usersProvider.isLoadingMore
                ? null
                : usersProvider.loadMoreUsers,
            child: usersProvider.isLoadingMore
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Load more'),
          ),
      ],
    );
  }
}
