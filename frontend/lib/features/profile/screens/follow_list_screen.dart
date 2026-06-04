import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../search/providers/users_provider.dart';
import '../../search/widgets/user_tile.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final int userId;
  final FollowListType type;
  final String title;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.title,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch(refresh: true);
    });
  }

  Future<void> _fetch({bool refresh = false}) {
    final usersProvider = context.read<UsersProvider>();
    return widget.type == FollowListType.followers
        ? usersProvider.fetchFollowers(widget.userId, refresh: refresh)
        : usersProvider.fetchFollowing(widget.userId, refresh: refresh);
  }

  Future<void> _loadMore() {
    final usersProvider = context.read<UsersProvider>();
    return widget.type == FollowListType.followers
        ? usersProvider.loadMoreFollowers(widget.userId)
        : usersProvider.loadMoreFollowing(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final users = widget.type == FollowListType.followers
        ? usersProvider.followers
        : usersProvider.following;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: () => _fetch(refresh: true),
        child: _FollowListBody(
          users: users,
          isLoading: usersProvider.isLoading,
          isLoadingMore: usersProvider.isLoadingMore,
          hasMore: usersProvider.hasMore,
          errorMessage: usersProvider.errorMessage,
          onRetry: () => _fetch(refresh: true),
          onLoadMore: _loadMore,
        ),
      ),
    );
  }
}

class _FollowListBody extends StatelessWidget {
  final List<UserModel> users;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  const _FollowListBody({
    required this.users,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.onRetry,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && users.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
          const SizedBox(height: 12),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (users.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(24),
        children: const [
          SizedBox(height: 96),
          Center(child: Text('No users found.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == users.length) {
          if (!hasMore) {
            return const SizedBox.shrink();
          }

          return OutlinedButton(
            onPressed: isLoadingMore ? null : onLoadMore,
            child: isLoadingMore
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Load more'),
          );
        }

        final user = users[index];
        return UserTile(
          user: user,
          onTap: () => context.push('/users/${user.id}'),
        );
      },
    );
  }
}
