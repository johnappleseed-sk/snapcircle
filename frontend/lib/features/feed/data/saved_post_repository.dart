import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../models/post_model.dart';
import '../models/saved_collection_model.dart';

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

  Future<PaginatedResponse<PostModel>> getSavedPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.savedPosts,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final response = _readData(result.data?.data, result.error);
    return PaginatedResponse<PostModel>.fromApi(
      response: response,
      itemBuilder: PostModel.fromJson,
      dataKey: 'posts',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<List<SavedCollectionModel>> getCollections() async {
    final result = await _apiClient.get(ApiEndpoints.savedCollections);
    final response = _readData(result.data?.data, result.error);
    final rawCollections = response['data'];
    if (rawCollections is! List) {
      return const [];
    }

    return rawCollections
        .whereType<Map>()
        .map(
          (item) =>
              SavedCollectionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<SavedCollectionModel> createCollection(String name) async {
    final result = await _apiClient.post(
      ApiEndpoints.savedCollections,
      data: {'name': name},
    );
    return _readCollection(result.data?.data, result.error);
  }

  Future<SavedCollectionModel> renameCollection(int id, String name) async {
    final result = await _apiClient.put(
      ApiEndpoints.savedCollection(id),
      data: {'name': name},
    );
    return _readCollection(result.data?.data, result.error);
  }

  Future<void> deleteCollection(int id) async {
    final result = await _apiClient.delete(ApiEndpoints.savedCollection(id));
    _readData(result.data?.data, result.error);
  }

  Future<SavedCollectionModel> addPostToCollection({
    required int collectionId,
    required int postId,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.savedCollectionPost(collectionId, postId),
    );
    return _readCollection(result.data?.data, result.error);
  }

  Future<SavedCollectionModel> removePostFromCollection({
    required int collectionId,
    required int postId,
  }) async {
    final result = await _apiClient.delete(
      ApiEndpoints.savedCollectionPost(collectionId, postId),
    );
    return _readCollection(result.data?.data, result.error);
  }

  Future<PaginatedResponse<PostModel>> getCollectionPosts({
    required int collectionId,
    int page = 1,
    int perPage = 10,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.savedCollectionPosts(collectionId),
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final response = _readData(result.data?.data, result.error);
    return PaginatedResponse<PostModel>.fromApi(
      response: response,
      itemBuilder: PostModel.fromJson,
      dataKey: 'posts',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
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

  SavedCollectionModel _readCollection(dynamic responseData, String? error) {
    final data = _readData(responseData, error);
    final collection = data['collection'];
    if (collection is Map<String, dynamic>) {
      return SavedCollectionModel.fromJson(collection);
    }

    throw const SavedPostException('Invalid collection response from API.');
  }
}
