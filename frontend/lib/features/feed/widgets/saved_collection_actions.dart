import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/saved_collection_model.dart';
import '../providers/saved_collections_provider.dart';

Future<void> showSavedCollectionDialog(
  BuildContext context, {
  SavedCollectionModel? collection,
}) async {
  final controller = TextEditingController(text: collection?.name ?? '');
  final formKey = GlobalKey<FormState>();
  final provider = context.read<SavedCollectionsProvider>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          collection == null ? 'Create collection' : 'Rename collection',
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name.' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) {
                return;
              }
              final name = controller.text.trim();
              final success = collection == null
                  ? await provider.createCollection(name)
                  : await provider.renameCollection(collection.id, name);
              if (!dialogContext.mounted) {
                return;
              }
              if (success) {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  SnackbarHelper.showSuccess(
                    context,
                    collection == null
                        ? 'Collection created.'
                        : 'Collection renamed.',
                  );
                }
              }
            },
            child: Text(collection == null ? 'Create' : 'Save'),
          ),
        ],
      );
    },
  );

  controller.dispose();
}

Future<void> showAddToCollectionSheet(
  BuildContext context, {
  required int postId,
}) async {
  final provider = context.read<SavedCollectionsProvider>();
  await provider.fetchCollections();
  if (!context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Consumer<SavedCollectionsProvider>(
          builder: (context, provider, _) {
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Create new collection'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showSavedCollectionDialog(context);
                  },
                ),
                if (provider.collections.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.collections_bookmark_outlined),
                    title: Text('No collections yet'),
                    subtitle: Text('Create one to organize this post.'),
                  )
                else
                  for (final collection in provider.collections)
                    ListTile(
                      leading: const Icon(Icons.collections_bookmark_outlined),
                      title: Text(collection.name),
                      subtitle: Text('${collection.postsCount} posts'),
                      onTap: provider.isSaving
                          ? null
                          : () async {
                              final success = await provider.addPost(
                                collection.id,
                                postId,
                              );
                              if (!sheetContext.mounted) {
                                return;
                              }
                              Navigator.of(sheetContext).pop();
                              if (context.mounted && success) {
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Added to ${collection.name}.',
                                );
                              }
                            },
                    ),
                const SizedBox(height: AppSizes.paddingSmall),
              ],
            );
          },
        ),
      );
    },
  );
}
