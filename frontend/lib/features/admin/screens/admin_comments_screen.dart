import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../comments/models/comment_model.dart';
import '../providers/admin_provider.dart';

class AdminCommentsScreen extends StatefulWidget {
  const AdminCommentsScreen({super.key});

  @override
  State<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchComments(
      search: _searchController.text,
      status: _statusFilter,
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<AdminProvider>().loadMoreComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Comment Moderation')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          itemCount: provider.comments.isEmpty
              ? 2
              : provider.comments.length + 2,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AdminCommentFilters(
                searchController: _searchController,
                status: _statusFilter,
                onStatusChanged: (value) {
                  setState(() => _statusFilter = value);
                  _fetch();
                },
                onSearch: _fetch,
                onClear: () {
                  _searchController.clear();
                  setState(() => _statusFilter = 'all');
                  _fetch();
                },
              );
            }

            if (provider.comments.isNotEmpty &&
                index == provider.comments.length + 1) {
              if (provider.isLoadingMoreComments) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMedium,
                  ),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (provider.hasMoreComments) {
                return OutlinedButton.icon(
                  onPressed: provider.loadMoreComments,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more comments'),
                );
              }

              return Center(
                child: Text(
                  'End of comment list',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            if (provider.isLoading && provider.comments.isEmpty) {
              return const SizedBox(
                height: 320,
                child: LoadingView(message: 'Loading comments...'),
              );
            }

            if (provider.errorMessage != null && provider.comments.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: _fetch,
              );
            }

            if (provider.comments.isEmpty) {
              return const EmptyView(
                icon: Icons.chat_bubble_outline,
                title: 'No comments found',
                subtitle: 'Try another search term or report filter.',
              );
            }

            return _AdminCommentTile(comment: provider.comments[index - 1]);
          },
        ),
      ),
    );
  }
}

class _AdminCommentFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _AdminCommentFilters({
    required this.searchController,
    required this.status,
    required this.onStatusChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              labelText: 'Search comments',
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Search',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _FilterDropdown(
            label: 'Reports',
            value: status,
            items: const {
              'all': 'All comments',
              'reported': 'Reported',
              'pending_report': 'Pending review',
              'unreported': 'Unreported',
            },
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _AdminCommentTile extends StatelessWidget {
  final CommentModel comment;

  const _AdminCommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: comment.user.name,
                imageUrl: comment.user.avatarUrl ?? comment.user.avatar,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user.name.isEmpty
                          ? 'Unknown user'
                          : comment.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(DateFormatter.timeAgo(comment.createdAt)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Comment actions',
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (context) => [
                  if (comment.postId != null)
                    const PopupMenuItem(
                      value: 'post',
                      child: Text('Open post'),
                    ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('Open author'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete comment'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(comment.comment, maxLines: 5, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSizes.paddingMedium),
          Chip(
            avatar: const Icon(Icons.flag_outlined, size: 16),
            label: Text(
              comment.pendingReportsCount > 0
                  ? '${comment.pendingReportsCount} pending reports'
                  : '${comment.reportsCount} reports',
            ),
            side: BorderSide(color: Theme.of(context).dividerColor),
            backgroundColor: AppColors.surfaceMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    switch (value) {
      case 'post':
        final postId = comment.postId;
        if (postId != null) {
          context.push('/posts/$postId');
        }
        return;
      case 'profile':
        context.push('/admin/users/${comment.user.id}');
        return;
      case 'delete':
        final confirmed = await _confirmDelete(context);
        if (!context.mounted || confirmed != true) {
          return;
        }
        final provider = context.read<AdminProvider>();
        final success = await provider.deleteComment(comment.id);
        if (!context.mounted) {
          return;
        }
        if (success) {
          SnackbarHelper.showSuccess(context, 'Comment deleted.');
        } else {
          SnackbarHelper.showError(
            context,
            provider.errorMessage ?? 'Unable to delete comment.',
          );
        }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This removes the comment from SnapCircle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
