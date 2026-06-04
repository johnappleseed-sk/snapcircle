import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class LikeException implements Exception {
  final String message;

  const LikeException(this.message);

  @override
  String toString() => message;
}

class LikeRepository {
  final ApiClient _apiClient;

  LikeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> likePost(int postId) async {
    final result = await _apiClient.post(ApiEndpoints.likePost(postId));
    return _parseLikeResponse(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> unlikePost(int postId) async {
    final result = await _apiClient.delete(ApiEndpoints.unlikePost(postId));
    return _parseLikeResponse(result.data?.data, result.error);
  }

  Map<String, dynamic> _parseLikeResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw LikeException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      return {};
    }

    final data = responseData['data'];
    final source = data is Map<String, dynamic> ? data : responseData;

    return {
      if (source.containsKey('likes_count'))
        'likes_count': _parseInt(source['likes_count']),
      if (source.containsKey('liked_by_me'))
        'liked_by_me': _parseBool(source['liked_by_me']),
    };
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }
}
