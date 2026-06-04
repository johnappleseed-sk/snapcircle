import 'package:flutter/foundation.dart';

import '../data/comment_repository.dart';
import '../models/comment_model.dart';

class CommentsProvider extends ChangeNotifier {
  final CommentRepository _commentRepository;

  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  CommentsProvider({CommentRepository? commentRepository})
    : _commentRepository = commentRepository ?? CommentRepository();

  List<CommentModel> get comments => List.unmodifiable(_comments);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchComments(int postId, {bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _comments.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedComments = await _commentRepository.getComments(
        postId,
        page: _currentPage,
      );
      _comments = fetchedComments;
      _hasMore = fetchedComments.isNotEmpty;
    } on CommentException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load comments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreComments(int postId) async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final fetchedComments = await _commentRepository.getComments(
        postId,
        page: nextPage,
      );

      if (fetchedComments.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        _comments = [..._comments, ...fetchedComments];
      }
    } on CommentException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more comments. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createComment(int postId, String comment) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdComment = await _commentRepository.createComment(
        postId,
        comment,
      );
      _comments = [createdComment, ..._comments];
      return true;
    } on CommentException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create comment. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateComment(int commentId, String comment) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedComment = await _commentRepository.updateComment(
        commentId,
        comment,
      );
      _comments = _comments
          .map((item) => item.id == commentId ? updatedComment : item)
          .toList();
      return true;
    } on CommentException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update comment. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(int commentId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentRepository.deleteComment(commentId);
      _comments = _comments
          .where((comment) => comment.id != commentId)
          .toList();
      return true;
    } on CommentException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete comment. Please try again.';
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
