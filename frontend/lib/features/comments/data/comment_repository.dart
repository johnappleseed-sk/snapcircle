import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
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

  Future<PaginatedResponse<CommentModel>> getComments(
    int postId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.postComments(postId),
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final response = _readResponse(result.data?.data, result.error);
    return PaginatedResponse<CommentModel>.fromApi(
      response: response,
      itemBuilder: CommentModel.fromJson,
      dataKey: 'comments',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
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
