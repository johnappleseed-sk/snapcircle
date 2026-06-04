import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/feed_repository.dart';
import '../models/post_model.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _feedRepository;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  FeedProvider({FeedRepository? feedRepository})
    : _feedRepository = feedRepository ?? FeedRepository();

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreating => _isCreating;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPosts({bool refresh = false}) async {
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
      final fetchedPosts = await _feedRepository.getPosts(page: _currentPage);
      _posts = fetchedPosts;
      _hasMore = fetchedPosts.isNotEmpty;
    } on FeedException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load posts. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final fetchedPosts = await _feedRepository.getPosts(page: nextPage);

      if (fetchedPosts.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        _posts = [..._posts, ...fetchedPosts];
      }
    } on FeedException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more posts. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createPost({String? content, File? image}) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final post = await _feedRepository.createPost(
        content: content,
        image: image,
      );
      _posts = [post, ..._posts];
      return true;
    } on FeedException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create post. Please try again.';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(int postId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _feedRepository.deletePost(postId);
      _posts = _posts.where((post) => post.id != postId).toList();
      return true;
    } on FeedException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete post. Please try again.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
