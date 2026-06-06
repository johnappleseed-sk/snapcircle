import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class ReportException implements Exception {
  final String message;

  const ReportException(this.message);

  @override
  String toString() => message;
}

class ReportRepository {
  final ApiClient _apiClient;

  ReportRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> reportPost(
    int postId, {
    required String reason,
    String? description,
  }) {
    return _report(
      ApiEndpoints.reportPost(postId),
      reason: reason,
      description: description,
    );
  }

  Future<void> reportComment(
    int commentId, {
    required String reason,
    String? description,
  }) {
    return _report(
      ApiEndpoints.reportComment(commentId),
      reason: reason,
      description: description,
    );
  }

  Future<void> reportUser(
    int userId, {
    required String reason,
    String? description,
  }) {
    return _report(
      ApiEndpoints.reportUser(userId),
      reason: reason,
      description: description,
    );
  }

  Future<void> _report(
    String path, {
    required String reason,
    String? description,
  }) async {
    final result = await _apiClient.post(
      path,
      data: {
        'reason': reason,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );

    if (!result.isSuccess) {
      throw ReportException(result.error ?? 'Unable to submit report.');
    }
  }
}
