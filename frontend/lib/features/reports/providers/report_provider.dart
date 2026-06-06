import 'package:flutter/foundation.dart';

import '../data/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;

  ReportProvider({ReportRepository? repository})
    : _repository = repository ?? ReportRepository();

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> reportPost(
    int postId, {
    required String reason,
    String? description,
  }) {
    return _submit(
      () => _repository.reportPost(
        postId,
        reason: reason,
        description: description,
      ),
    );
  }

  Future<bool> reportComment(
    int commentId, {
    required String reason,
    String? description,
  }) {
    return _submit(
      () => _repository.reportComment(
        commentId,
        reason: reason,
        description: description,
      ),
    );
  }

  Future<bool> reportUser(
    int userId, {
    required String reason,
    String? description,
  }) {
    return _submit(
      () => _repository.reportUser(
        userId,
        reason: reason,
        description: description,
      ),
    );
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on ReportException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to submit report. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
