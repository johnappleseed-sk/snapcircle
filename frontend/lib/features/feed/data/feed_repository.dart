import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../models/post_model.dart';

class FeedException implements Exception {
  final String message;

  const FeedException(this.message);

  @override
  String toString() => message;
}

class FeedRepository {
  final ApiClient _apiClient;

  FeedRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<PaginatedResponse<PostModel>> getPosts({
    int page = 1,
    String mode = 'all',
    String? search,
    int perPage = 10,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'mode': mode,
      'per_page': perPage,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final result = await _apiClient.get(
      ApiEndpoints.posts,
      queryParameters: queryParameters,
    );

    final response = _readResponse(result.data?.data, result.error);
    final postsJson = _extractPostsList(response);
    return PaginatedResponse<PostModel>(
      items: postsJson.map(PostModel.fromJson).toList(),
      currentPage: _parseInt(response['current_page'], fallback: page),
      lastPage: _parseInt(response['last_page'], fallback: page),
      perPage: _parseInt(response['per_page'], fallback: perPage),
      total: _parseInt(response['total'], fallback: postsJson.length),
    );
  }

  Future<PostModel> createPost({String? content, File? image}) async {
    final result = await _apiClient.post(
      ApiEndpoints.createPost,
      data: await _buildPostData(content: content, image: image),
    );

    return _parsePostResponse(result.data?.data, result.error);
  }

  Future<PostModel> getPost(int postId) async {
    final result = await _apiClient.get(ApiEndpoints.postById(postId));
    return _parsePostResponse(result.data?.data, result.error);
  }

  Future<PostModel> updatePost(
    int postId, {
    String? content,
    File? image,
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.postById(postId),
      data: await _buildPostData(content: content, image: image),
    );

    return _parsePostResponse(result.data?.data, result.error);
  }

  Future<void> deletePost(int postId) async {
    final result = await _apiClient.delete(ApiEndpoints.postById(postId));
    if (!result.isSuccess) {
      throw FeedException(result.error ?? 'Unable to delete this post.');
    }
  }

  Future<FormData> _buildPostData({String? content, File? image}) async {
    final data = <String, dynamic>{};
    final trimmedContent = content?.trim();

    if (trimmedContent != null && trimmedContent.isNotEmpty) {
      data['content'] = trimmedContent;
    }

    if (image != null) {
      data['image'] = await MultipartFile.fromFile(
        image.path,
        filename: image.path.split(Platform.pathSeparator).last,
      );
    }

    return FormData.fromMap(data);
  }

  PostModel _parsePostResponse(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final postJson = _extractPostJson(response);

    if (postJson == null) {
      throw const FeedException('Invalid post response from API.');
    }

    return PostModel.fromJson(postJson);
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw FeedException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const FeedException('Invalid response from API.');
    }

    return responseData;
  }

  List<Map<String, dynamic>> _extractPostsList(Map<String, dynamic> response) {
    final data = response['data'];
    final posts = data is List
        ? data
        : response['posts'] is List
        ? response['posts']
        : data is Map<String, dynamic> && data['data'] is List
        ? data['data']
        : null;

    if (posts is! List) {
      throw const FeedException('Invalid posts response from API.');
    }

    return posts.whereType<Map<String, dynamic>>().toList();
  }

  int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  Map<String, dynamic>? _extractPostJson(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic> && data['post'] is Map<String, dynamic>) {
      return data['post'] as Map<String, dynamic>;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (response['post'] is Map<String, dynamic>) {
      return response['post'] as Map<String, dynamic>;
    }

    return null;
  }
}
