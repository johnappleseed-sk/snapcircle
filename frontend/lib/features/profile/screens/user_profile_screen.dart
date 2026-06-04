import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchUserById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final selectedUser = profileProvider.selectedUser;
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: RefreshIndicator(
        onRefresh: () => profileProvider.fetchUserById(widget.userId),
        child: _UserProfileBody(
          user: selectedUser,
          currentUserId: currentUserId,
          isLoading: profileProvider.isLoading,
          isFollowing: profileProvider.isFollowing,
          errorMessage: profileProvider.errorMessage,
          onRetry: () => profileProvider.fetchUserById(widget.userId),
        ),
      ),
    );
  }
}

class _UserProfileBody extends StatelessWidget {
  final UserModel? user;
  final int? currentUserId;
  final bool isLoading;
  final bool isFollowing;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _UserProfileBody({
    required this.user,
    required this.currentUserId,
    required this.isLoading,
    required this.isFollowing,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && user == null) {
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

    if (user == null) {
      return ListView(
        padding: EdgeInsets.all(24),
        children: const [
          SizedBox(height: 96),
          Center(child: Text('User not found.')),
        ],
      );
    }

    final loadedUser = user!;
    final isCurrentUser =
        currentUserId != null && currentUserId == loadedUser.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _Avatar(imageUrl: loadedUser.avatar),
              const SizedBox(height: 12),
              Text(
                loadedUser.name,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (loadedUser.bio != null &&
                  loadedUser.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(loadedUser.bio!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatButton(
                      label: 'Posts',
                      value: loadedUser.postsCount,
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      label: 'Followers',
                      value: loadedUser.followersCount,
                      onTap: () => _openFollowList(context, 'followers'),
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      label: 'Following',
                      value: loadedUser.followingCount,
                      onTap: () => _openFollowList(context, 'following'),
                    ),
                  ),
                ],
              ),
              if (!isCurrentUser) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: loadedUser.isFollowedByMe
                      ? OutlinedButton.icon(
                          onPressed: isFollowing
                              ? null
                              : () => context
                                    .read<ProfileProvider>()
                                    .unfollowUser(loadedUser.id),
                          icon: const Icon(Icons.person_remove_outlined),
                          label: Text(isFollowing ? 'Updating...' : 'Unfollow'),
                        )
                      : FilledButton.icon(
                          onPressed: isFollowing
                              ? null
                              : () => context
                                    .read<ProfileProvider>()
                                    .followUser(loadedUser.id),
                          icon: const Icon(Icons.person_add_outlined),
                          label: Text(isFollowing ? 'Updating...' : 'Follow'),
                        ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'User posts will be improved later.',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }

  void _openFollowList(BuildContext context, String type) {
    context.push('/users/${user!.id}/$type');
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;

  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }

    return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48));
  }
}

class _StatButton extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _StatButton({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
