import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/feed_repository.dart';
import '../data/like_repository.dart';
import '../models/post_model.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _feedRepository;
  final LikeRepository _likeRepository;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isCreating = false;
  final Set<int> _likingPostIds = {};
  bool _hasMore = true;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _perPage = 10;
  String _currentMode = 'all';
  String? _searchQuery;
  String? _errorMessage;

  FeedProvider({FeedRepository? feedRepository, LikeRepository? likeRepository})
    : _feedRepository = feedRepository ?? FeedRepository(),
      _likeRepository = likeRepository ?? LikeRepository();

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get isCreating => _isCreating;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get perPage => _perPage;
  String get currentMode => _currentMode;
  String? get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool isLikeUpdating(int postId) => _likingPostIds.contains(postId);

  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore || _isRefreshing) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _posts.isEmpty;
    _isRefreshing = refresh && _posts.isNotEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _feedRepository.getPosts(
        page: _currentPage,
        mode: _currentMode,
        search: _searchQuery,
        perPage: _perPage,
      );
      _posts = response.items;
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      _hasMore = response.hasMore;
    } on FeedException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load posts. Please try again.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
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
      final response = await _feedRepository.getPosts(
        page: nextPage,
        mode: _currentMode,
        search: _searchQuery,
        perPage: _perPage,
      );

      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      _hasMore = response.hasMore;

      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _posts = [..._posts, ...response.items];
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

  Future<void> changeMode(String mode) async {
    if (_currentMode == mode) {
      return;
    }

    _currentMode = mode;
    await fetchPosts(refresh: true);
  }

  Future<void> searchPosts(String query) async {
    final trimmed = query.trim();
    _searchQuery = trimmed.isEmpty ? null : trimmed;
    await fetchPosts(refresh: true);
  }

  Future<void> clearSearch() async {
    if (_searchQuery == null) {
      return;
    }

    _searchQuery = null;
    await fetchPosts(refresh: true);
  }

  Future<void> refreshPosts() {
    return fetchPosts(refresh: true);
  }

  Future<PostModel?> getPostById(int postId) async {
    final localPost = _findPost(postId);
    if (localPost != null) {
      return localPost;
    }

    try {
      return await _feedRepository.getPost(postId);
    } on FeedException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Unable to load this post. Please try again.';
      notifyListeners();
      return null;
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
      if (_currentMode == 'all' || _currentMode == 'mine') {
        _posts = [post, ..._posts];
      }
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

  Future<bool> likePost(int postId) async {
    if (_likingPostIds.contains(postId)) {
      return false;
    }

    return _setLikeState(postId, shouldLike: true);
  }

  Future<bool> unlikePost(int postId) async {
    if (_likingPostIds.contains(postId)) {
      return false;
    }

    return _setLikeState(postId, shouldLike: false);
  }

  Future<bool> toggleLike(int postId) async {
    final post = _findPost(postId);
    if (post == null) {
      return false;
    }

    return post.likedByMe ? unlikePost(postId) : likePost(postId);
  }

  void incrementCommentCount(int postId) {
    _updatePost(
      postId,
      (post) => post.copyWith(commentsCount: post.commentsCount + 1),
    );
  }

  void decrementCommentCount(int postId) {
    _updatePost(
      postId,
      (post) => post.copyWith(
        commentsCount: post.commentsCount > 0 ? post.commentsCount - 1 : 0,
      ),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void upsertPost(PostModel updatedPost) {
    final exists = _posts.any((post) => post.id == updatedPost.id);
    _posts = exists
        ? _posts
              .map((post) => post.id == updatedPost.id ? updatedPost : post)
              .toList()
        : [updatedPost, ..._posts];
    notifyListeners();
  }

  Future<bool> _setLikeState(int postId, {required bool shouldLike}) async {
    final originalPost = _findPost(postId);
    if (originalPost == null) {
      return false;
    }

    _likingPostIds.add(postId);
    _errorMessage = null;
    _updatePost(
      postId,
      (post) => post.copyWith(
        likedByMe: shouldLike,
        likesCount: _optimisticLikesCount(post, shouldLike: shouldLike),
      ),
      shouldNotify: false,
    );
    notifyListeners();

    try {
      final response = shouldLike
          ? await _likeRepository.likePost(postId)
          : await _likeRepository.unlikePost(postId);

      _updatePost(
        postId,
        (post) => post.copyWith(
          likesCount: response['likes_count'] is int
              ? response['likes_count'] as int
              : post.likesCount,
          likedByMe: response['liked_by_me'] is bool
              ? response['liked_by_me'] as bool
              : shouldLike,
        ),
        shouldNotify: false,
      );
      return true;
    } on LikeException catch (error) {
      _errorMessage = error.message;
      _replacePost(originalPost, shouldNotify: false);
      return false;
    } catch (_) {
      _errorMessage = shouldLike
          ? 'Unable to like this post. Please try again.'
          : 'Unable to unlike this post. Please try again.';
      _replacePost(originalPost, shouldNotify: false);
      return false;
    } finally {
      _likingPostIds.remove(postId);
      notifyListeners();
    }
  }

  PostModel? _findPost(int postId) {
    for (final post in _posts) {
      if (post.id == postId) {
        return post;
      }
    }

    return null;
  }

  int _optimisticLikesCount(PostModel post, {required bool shouldLike}) {
    if (shouldLike && !post.likedByMe) {
      return post.likesCount + 1;
    }

    if (!shouldLike && post.likedByMe) {
      return post.likesCount > 0 ? post.likesCount - 1 : 0;
    }

    return post.likesCount;
  }

  void _replacePost(PostModel post, {bool shouldNotify = true}) {
    _updatePost(post.id, (_) => post, shouldNotify: shouldNotify);
  }

  void _updatePost(
    int postId,
    PostModel Function(PostModel post) update, {
    bool shouldNotify = true,
  }) {
    _posts = _posts.map((post) {
      if (post.id != postId) {
        return post;
      }

      return update(post);
    }).toList();

    if (shouldNotify) {
      notifyListeners();
    }
  }
}
