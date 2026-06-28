import 'package:flutter/foundation.dart';

import '../data/saved_post_repository.dart';
import '../models/post_model.dart';
import '../models/saved_collection_model.dart';

class SavedCollectionsProvider extends ChangeNotifier {
  final SavedPostRepository _repository;

  List<SavedCollectionModel> _collections = [];
  final Map<int, List<PostModel>> _collectionPosts = {};
  final Set<int> _loadingCollectionIds = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  SavedCollectionsProvider({SavedPostRepository? repository})
    : _repository = repository ?? SavedPostRepository();

  List<SavedCollectionModel> get collections => List.unmodifiable(_collections);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<PostModel> postsFor(int collectionId) {
    return List.unmodifiable(_collectionPosts[collectionId] ?? const []);
  }

  bool isLoadingPosts(int collectionId) {
    return _loadingCollectionIds.contains(collectionId);
  }

  Future<void> fetchCollections({bool refresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!refresh && _collections.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _collections = await _repository.getCollections();
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load saved collections.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCollection(String name) async {
    return _runCollectionMutation(() => _repository.createCollection(name));
  }

  Future<bool> renameCollection(int id, String name) async {
    return _runCollectionMutation(() => _repository.renameCollection(id, name));
  }

  Future<bool> deleteCollection(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCollection(id);
      _collections = _collections.where((item) => item.id != id).toList();
      _collectionPosts.remove(id);
      return true;
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete this collection.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> addPost(int collectionId, int postId) async {
    return _runCollectionMutation(
      () => _repository.addPostToCollection(
        collectionId: collectionId,
        postId: postId,
      ),
    );
  }

  Future<bool> removePost(int collectionId, int postId) async {
    final success = await _runCollectionMutation(
      () => _repository.removePostFromCollection(
        collectionId: collectionId,
        postId: postId,
      ),
    );
    if (success) {
      _collectionPosts[collectionId] = postsFor(
        collectionId,
      ).where((post) => post.id != postId).toList();
      notifyListeners();
    }
    return success;
  }

  Future<void> fetchCollectionPosts(int collectionId) async {
    if (_loadingCollectionIds.contains(collectionId)) {
      return;
    }

    _loadingCollectionIds.add(collectionId);
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getCollectionPosts(
        collectionId: collectionId,
      );
      _collectionPosts[collectionId] = response.items;
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load collection posts.';
    } finally {
      _loadingCollectionIds.remove(collectionId);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runCollectionMutation(
    Future<SavedCollectionModel> Function() action,
  ) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collection = await action();
      _upsert(collection);
      return true;
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update saved collection.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _upsert(SavedCollectionModel collection) {
    final exists = _collections.any((item) => item.id == collection.id);
    _collections = exists
        ? _collections
              .map((item) => item.id == collection.id ? collection : item)
              .toList()
        : [collection, ..._collections];
  }
}
