import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
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

  Future<List<PostModel>> getPosts({int page = 1, String? search}) async {
    final queryParameters = <String, dynamic>{'page': page};
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final result = await _apiClient.get(
      ApiEndpoints.posts,
      queryParameters: queryParameters,
    );

    final response = _readResponse(result.data?.data, result.error);
    final postsJson = _extractPostsList(response);
    return postsJson.map(PostModel.fromJson).toList();
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
    final nestedData = data is Map<String, dynamic> ? data['data'] : null;
    final posts = nestedData is List ? nestedData : data;

    if (posts is! List) {
      throw const FeedException('Invalid posts response from API.');
    }

    return posts.whereType<Map<String, dynamic>>().toList();
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
