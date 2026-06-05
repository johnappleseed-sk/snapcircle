import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/post_model.dart';

class SavedPostException implements Exception {
  final String message;

  const SavedPostException(this.message);

  @override
  String toString() => message;
}

class SavedPostRepository {
  final ApiClient _apiClient;

  SavedPostRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> savePost(int postId) async {
    final result = await _apiClient.post(ApiEndpoints.savePost(postId));
    return _readData(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> unsavePost(int postId) async {
    final result = await _apiClient.delete(ApiEndpoints.unsavePost(postId));
    return _readData(result.data?.data, result.error);
  }

  Future<List<PostModel>> getSavedPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.savedPosts,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final response = _readData(result.data?.data, result.error);
    final data = response['data'];

    if (data is! List) {
      throw const SavedPostException('Invalid saved posts response from API.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _readData(dynamic responseData, String? error) {
    if (error != null) {
      throw SavedPostException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const SavedPostException('Invalid response from API.');
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return responseData;
  }
}
