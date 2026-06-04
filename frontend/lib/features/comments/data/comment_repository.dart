import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/comment_model.dart';

class CommentException implements Exception {
  final String message;

  const CommentException(this.message);

  @override
  String toString() => message;
}

class CommentRepository {
  final ApiClient _apiClient;

  CommentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<CommentModel>> getComments(int postId, {int page = 1}) async {
    final result = await _apiClient.get(
      ApiEndpoints.postComments(postId),
      queryParameters: {'page': page},
    );

    final response = _readResponse(result.data?.data, result.error);
    final commentsJson = _extractCommentsList(response);
    return commentsJson.map(CommentModel.fromJson).toList();
  }

  Future<CommentModel> createComment(int postId, String comment) async {
    final result = await _apiClient.post(
      ApiEndpoints.postComments(postId),
      data: {'comment': comment.trim()},
    );

    return _parseCommentResponse(result.data?.data, result.error);
  }

  Future<CommentModel> updateComment(int commentId, String comment) async {
    final result = await _apiClient.put(
      ApiEndpoints.commentById(commentId),
      data: {'comment': comment.trim()},
    );

    return _parseCommentResponse(result.data?.data, result.error);
  }

  Future<void> deleteComment(int commentId) async {
    final result = await _apiClient.delete(ApiEndpoints.commentById(commentId));
    if (!result.isSuccess) {
      throw CommentException(result.error ?? 'Unable to delete this comment.');
    }
  }

  CommentModel _parseCommentResponse(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final commentJson = _extractCommentJson(response);

    if (commentJson == null) {
      throw const CommentException('Invalid comment response from API.');
    }

    return CommentModel.fromJson(commentJson);
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw CommentException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const CommentException('Invalid response from API.');
    }

    return responseData;
  }

  List<Map<String, dynamic>> _extractCommentsList(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];
    final nestedData = data is Map<String, dynamic> ? data['data'] : null;
    final comments = nestedData is List ? nestedData : data;

    if (comments is! List) {
      throw const CommentException('Invalid comments response from API.');
    }

    return comments.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic>? _extractCommentJson(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic> &&
        data['comment'] is Map<String, dynamic>) {
      return data['comment'] as Map<String, dynamic>;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (response['comment'] is Map<String, dynamic>) {
      return response['comment'] as Map<String, dynamic>;
    }

    return null;
  }
}
