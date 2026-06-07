import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/realtime_config.dart';
import '../../../core/realtime/realtime_repository.dart';
import '../data/comment_repository.dart';
import '../models/comments_status_model.dart';
import '../models/comment_model.dart';

class CommentsProvider extends ChangeNotifier {
  final CommentRepository _commentRepository;
  final RealtimeRepository _realtimeRepository;

  List<CommentModel> _comments = [];
  Timer? _commentsStatusTimer;
  CommentsStatusModel? _commentsStatus;
  bool _hasNewComments = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 15;
  String? _errorMessage;

  CommentsProvider({
    CommentRepository? commentRepository,
    RealtimeRepository? realtimeRepository,
  }) : _commentRepository = commentRepository ?? CommentRepository(),
       _realtimeRepository = realtimeRepository ?? RealtimeRepository();

  List<CommentModel> get comments => List.unmodifiable(_comments);
  CommentsStatusModel? get commentsStatus => _commentsStatus;
  bool get hasNewComments => _hasNewComments;
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
      final response = await _commentRepository.getComments(
        postId,
        page: _currentPage,
        perPage: _perPage,
      );
      _comments = response.items;
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
      markCommentsAsSeen();
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
      final response = await _commentRepository.getComments(
        postId,
        page: nextPage,
        perPage: _perPage,
      );

      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        _comments = _mergeComments(_comments, response.items);
        _hasMore = response.hasMore;
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
      markCommentsAsSeen();
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
      markCommentsAsSeen();
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

  void startCommentsStatusPolling(int postId) {
    if (_commentsStatusTimer != null) {
      return;
    }

    unawaited(checkCommentsStatus(postId));
    _commentsStatusTimer = Timer.periodic(
      RealtimeConfig.commentsStatusPollInterval,
      (_) => unawaited(checkCommentsStatus(postId)),
    );
  }

  void stopCommentsStatusPolling() {
    _commentsStatusTimer?.cancel();
    _commentsStatusTimer = null;
  }

  Future<void> checkCommentsStatus(int postId) async {
    try {
      final status = await _realtimeRepository.getCommentsStatus(postId);
      _commentsStatus = status;
      _hasNewComments = status.commentsCount > _comments.length;
      notifyListeners();
    } catch (_) {
      // Status polling should stay quiet; the full comments request owns errors.
    }
  }

  void markCommentsAsSeen() {
    _hasNewComments = false;
    notifyListeners();
  }

  List<CommentModel> _mergeComments(
    List<CommentModel> current,
    List<CommentModel> next,
  ) {
    final seenIds = current.map((comment) => comment.id).toSet();
    return [...current, ...next.where((comment) => seenIds.add(comment.id))];
  }

  @override
  void dispose() {
    _commentsStatusTimer?.cancel();
    super.dispose();
  }
}
