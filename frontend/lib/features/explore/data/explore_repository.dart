import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';
import '../models/trending_tag_model.dart';

class ExploreException implements Exception {
  final String message;

  const ExploreException(this.message);

  @override
  String toString() => message;
}

class ExploreRepository {
  final ApiClient _apiClient;

  ExploreRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<PostModel>> getExplorePosts({
    int page = 1,
    int perPage = 12,
    String? search,
    String sort = 'latest',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'sort': sort,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final result = await _apiClient.get(
      ApiEndpoints.explorePosts,
      queryParameters: query,
    );

    return _parsePosts(result.data?.data, result.error);
  }

  Future<List<UserModel>> getExploreUsers({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final result = await _apiClient.get(
      ApiEndpoints.exploreUsers,
      queryParameters: query,
    );

    return _parseUsers(result.data?.data, result.error);
  }

  Future<List<PostModel>> getTrendingPosts({
    int page = 1,
    int perPage = 12,
    int days = 7,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.trendingPosts,
      queryParameters: {'page': page, 'per_page': perPage, 'days': days},
    );

    return _parsePosts(result.data?.data, result.error);
  }

  Future<List<TrendingTagModel>> getTrendingTags({
    int limit = 12,
    int days = 30,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.trendingTags,
      queryParameters: {'limit': limit, 'days': days},
    );

    return _parseTags(result.data?.data, result.error);
  }

  Future<List<PostModel>> getPostsByTag({
    required String tag,
    int page = 1,
    int perPage = 12,
    String sort = 'latest',
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.tagPosts(Uri.encodeComponent(tag)),
      queryParameters: {'page': page, 'per_page': perPage, 'sort': sort},
    );

    return _parsePosts(result.data?.data, result.error);
  }

  Future<List<UserModel>> getRecommendedUsers({
    int page = 1,
    int perPage = 10,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.recommendedUsers,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return _parseUsers(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> globalSearch({
    required String query,
    String type = 'all',
    int page = 1,
    int perPage = 10,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.exploreSearch,
      queryParameters: {
        'q': query.trim(),
        'type': type,
        'page': page,
        'per_page': perPage,
      },
    );
    final response = _readResponse(result.data?.data, result.error);
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ExploreException('Invalid search response from API.');
    }

    return {
      'posts': _extractList(data, 'posts').map(PostModel.fromJson).toList(),
      'users': _extractList(data, 'users').map(UserModel.fromJson).toList(),
    };
  }

  List<PostModel> _parsePosts(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    return _extractList(response, 'posts').map(PostModel.fromJson).toList();
  }

  List<UserModel> _parseUsers(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    return _extractList(response, 'users').map(UserModel.fromJson).toList();
  }

  List<TrendingTagModel> _parseTags(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    return _extractList(
      response,
      'tags',
    ).map(TrendingTagModel.fromJson).toList();
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw ExploreException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const ExploreException('Invalid response from API.');
    }

    return responseData;
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
    String key,
  ) {
    final data = response['data'];
    final list = data is List
        ? data
        : response[key] is List
        ? response[key]
        : data is Map<String, dynamic> && data['data'] is List
        ? data['data']
        : data is Map<String, dynamic> && data[key] is List
        ? data[key]
        : null;

    if (list is! List) {
      return const [];
    }

    return list.whereType<Map<String, dynamic>>().toList();
  }
}
