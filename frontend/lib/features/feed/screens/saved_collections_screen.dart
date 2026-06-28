import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/saved_collection_model.dart';
import '../providers/saved_collections_provider.dart';
import '../widgets/saved_collection_actions.dart';
import '../widgets/post_card.dart';

class SavedCollectionsScreen extends StatefulWidget {
  const SavedCollectionsScreen({super.key});

  @override
  State<SavedCollectionsScreen> createState() => _SavedCollectionsScreenState();
}

class _SavedCollectionsScreenState extends State<SavedCollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedCollectionsProvider>().fetchCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedCollectionsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Collections'),
        actions: [
          IconButton(
            onPressed: () => showSavedCollectionDialog(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create collection',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchCollections(refresh: true),
        child: provider.isLoading && provider.collections.isEmpty
            ? const LoadingView(message: 'Loading collections...')
            : provider.errorMessage != null && provider.collections.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchCollections(refresh: true),
                  ),
                ],
              )
            : provider.collections.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  EmptyView(
                    icon: Icons.collections_bookmark_outlined,
                    title: 'No collections yet',
                    subtitle: 'Create a collection to organize posts you save.',
                    actionLabel: 'Create collection',
                    onAction: () => showSavedCollectionDialog(context),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: provider.collections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSizes.paddingMedium),
                itemBuilder: (context, index) {
                  final collection = provider.collections[index];
                  return _SavedCollectionTile(collection: collection);
                },
              ),
      ),
    );
  }
}

class SavedCollectionDetailScreen extends StatefulWidget {
  final int collectionId;
  final String? title;

  const SavedCollectionDetailScreen({
    super.key,
    required this.collectionId,
    this.title,
  });

  @override
  State<SavedCollectionDetailScreen> createState() =>
      _SavedCollectionDetailScreenState();
}

class _SavedCollectionDetailScreenState
    extends State<SavedCollectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedCollectionsProvider>().fetchCollectionPosts(
        widget.collectionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedCollectionsProvider>();
    final posts = provider.postsFor(widget.collectionId);
    final isLoading = provider.isLoadingPosts(widget.collectionId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Saved Collection')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchCollectionPosts(widget.collectionId),
        child: isLoading && posts.isEmpty
            ? const LoadingView(message: 'Loading collection...')
            : posts.isEmpty
            ? const _EmptyCollection()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: posts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSizes.paddingMedium),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    onTap: () => context.push('/posts/${post.id}', extra: post),
                    onCommentsTap: () =>
                        context.push('/posts/${post.id}/comments', extra: post),
                    onSaveTap: () =>
                        provider.removePost(widget.collectionId, post.id),
                  );
                },
              ),
      ),
    );
  }
}

class _SavedCollectionTile extends StatelessWidget {
  final SavedCollectionModel collection;

  const _SavedCollectionTile({required this.collection});

  @override
  Widget build(BuildContext context) {
    final latestPost = collection.latestPost;
    return AppCard(
      onTap: () => context.push(
        '/saved-collections/${collection.id}',
        extra: collection,
      ),
      child: Row(
        children: [
          AppAvatar(
            name: collection.name,
            imageUrl: latestPost?.imageUrl,
            size: AppAvatarSize.large,
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${collection.postsCount} saved ${collection.postsCount == 1 ? 'post' : 'posts'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (collection.updatedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Updated ${DateFormatter.timeAgo(collection.updatedAt)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_CollectionAction>(
            onSelected: (action) async {
              switch (action) {
                case _CollectionAction.rename:
                  showSavedCollectionDialog(context, collection: collection);
                case _CollectionAction.delete:
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'Delete collection?',
                    message:
                        'Saved posts stay saved, but this collection is removed.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed && context.mounted) {
                    final success = await context
                        .read<SavedCollectionsProvider>()
                        .deleteCollection(collection.id);
                    if (context.mounted && success) {
                      SnackbarHelper.showSuccess(
                        context,
                        'Collection deleted.',
                      );
                    }
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CollectionAction.rename,
                child: Text('Rename'),
              ),
              PopupMenuItem(
                value: _CollectionAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      children: const [
        SizedBox(height: 96),
        EmptyView(
          icon: Icons.collections_bookmark_outlined,
          title: 'Collection is empty',
          subtitle: 'Add saved posts to this collection from a post menu.',
        ),
      ],
    );
  }
}

enum _CollectionAction { rename, delete }
