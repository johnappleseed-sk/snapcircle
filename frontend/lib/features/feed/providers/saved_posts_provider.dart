import 'package:flutter/foundation.dart';

import '../data/saved_post_repository.dart';
import '../models/post_model.dart';

class SavedPostsProvider extends ChangeNotifier {
  final SavedPostRepository _repository;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 10;
  String? _errorMessage;

  SavedPostsProvider({SavedPostRepository? repository})
    : _repository = repository ?? SavedPostRepository();

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavedPosts({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _posts.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedPosts = await _repository.getSavedPosts(
        page: _currentPage,
        perPage: _perPage,
      );
      _posts = fetchedPosts;
      _hasMore = fetchedPosts.length >= _perPage;
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load saved posts. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSavedPosts() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final fetchedPosts = await _repository.getSavedPosts(
        page: nextPage,
        perPage: _perPage,
      );

      if (fetchedPosts.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        _posts = [..._posts, ...fetchedPosts];
        _hasMore = fetchedPosts.length >= _perPage;
      }
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more saved posts. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> unsavePost(int postId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.unsavePost(postId);
      removeSavedPost(postId);
      return true;
    } on SavedPostException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Unable to remove this saved post. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void removeSavedPost(int postId) {
    _posts = _posts.where((post) => post.id != postId).toList();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
