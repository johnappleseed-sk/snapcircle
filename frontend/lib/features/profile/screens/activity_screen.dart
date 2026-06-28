import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../feed/models/post_model.dart';
import '../models/activity_model.dart';
import '../providers/activity_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().fetchActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final activity = provider.activity;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Activity'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Comments'),
              Tab(text: 'Likes'),
              Tab(text: 'Saved'),
              Tab(text: 'Follows'),
            ],
          ),
        ),
        body: provider.isLoading && activity == null
            ? const LoadingView(message: 'Loading activity...')
            : provider.errorMessage != null && activity == null
            ? ErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.fetchActivity(refresh: true),
              )
            : RefreshIndicator(
                onRefresh: () => provider.fetchActivity(refresh: true),
                child: TabBarView(
                  children: [
                    _PostActivityList(posts: activity?.posts ?? const []),
                    _CommentActivityList(
                      comments: activity?.comments ?? const [],
                    ),
                    _PostActivityList(posts: activity?.likes ?? const []),
                    _PostActivityList(posts: activity?.saved ?? const []),
                    _FollowActivityList(follows: activity?.follows ?? const []),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PostActivityList extends StatelessWidget {
  final List<PostModel> posts;

  const _PostActivityList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _ActivityEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: posts.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingSmall),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostActivityTile(post: post);
      },
    );
  }
}

class _CommentActivityList extends StatelessWidget {
  final List<ActivityCommentModel> comments;

  const _CommentActivityList({required this.comments});

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const _ActivityEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: comments.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingSmall),
      itemBuilder: (context, index) {
        final comment = comments[index];
        final post = comment.post;
        return AppCard(
          onTap: post == null
              ? null
              : () => context.push('/posts/${post.id}', extra: post),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.comment,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                comment.createdAt == null
                    ? 'Commented'
                    : 'Commented ${DateFormatter.timeAgo(comment.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FollowActivityList extends StatelessWidget {
  final List<ActivityFollowModel> follows;

  const _FollowActivityList({required this.follows});

  @override
  Widget build(BuildContext context) {
    if (follows.isEmpty) {
      return const _ActivityEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: follows.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingSmall),
      itemBuilder: (context, index) {
        final follow = follows[index];
        final user = follow.user;
        return AppCard(
          onTap: user == null ? null : () => context.push('/users/${user.id}'),
          child: Row(
            children: [
              AppAvatar(
                name: user?.name ?? 'User',
                imageUrl: user?.avatarUrl ?? user?.avatar,
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  user == null ? 'Followed user' : 'Followed ${user.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostActivityTile extends StatelessWidget {
  final PostModel post;

  const _PostActivityTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/posts/${post.id}', extra: post),
      child: Row(
        children: [
          AppAvatar(
            name: post.user.name,
            imageUrl: post.user.avatarUrl ?? post.user.avatar,
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content?.trim().isNotEmpty == true
                      ? post.content!.trim()
                      : 'SnapCircle post',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  post.createdAt == null
                      ? '${post.likesCount} likes'
                      : '${DateFormatter.timeAgo(post.createdAt)} · ${post.likesCount} likes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      children: const [
        SizedBox(height: 96),
        EmptyView(
          icon: Icons.history_rounded,
          title: 'No activity yet',
          subtitle: 'Your recent SnapCircle activity will appear here.',
        ),
      ],
    );
  }
}
