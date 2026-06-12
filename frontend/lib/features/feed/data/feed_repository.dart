import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/utils/image_compressor.dart';
import '../models/post_model.dart';

class FeedException implements Exception {
  final String message;

  const FeedException(this.message);

  @override
  String toString() => message;
}

class FeedRepository {
  final ApiClient _apiClient;
  final ImageCompressor _imageCompressor;

  FeedRepository({ApiClient? apiClient, ImageCompressor? imageCompressor})
    : _apiClient = apiClient ?? ApiClient(),
      _imageCompressor = imageCompressor ?? const ImageCompressor();

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
    return PaginatedResponse<PostModel>.fromApi(
      response: response,
      itemBuilder: PostModel.fromJson,
      dataKey: 'posts',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<PostModel> createPost({
    String? content,
    File? image,
    List<File> images = const [],
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.createPost,
      data: await _buildPostData(content: content, image: image, images: images),
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
    List<File> images = const [],
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.postById(postId),
      data: await _buildPostData(content: content, image: image, images: images),
    );

    return _parsePostResponse(result.data?.data, result.error);
  }

  Future<void> deletePost(int postId) async {
    final result = await _apiClient.delete(ApiEndpoints.postById(postId));
    if (!result.isSuccess) {
      throw FeedException(result.error ?? 'Unable to delete this post.');
    }
  }

  Future<FormData> _buildPostData({
    String? content,
    File? image,
    List<File> images = const [],
  }) async {
    final data = <String, dynamic>{};
    final trimmedContent = content?.trim();

    if (trimmedContent != null && trimmedContent.isNotEmpty) {
      data['content'] = trimmedContent;
    }

    final uploadImages = images.isNotEmpty
        ? images
        : (image == null ? const <File>[] : [image]);

    if (uploadImages.length == 1 && image != null && images.isEmpty) {
      final uploadImage = await _imageCompressor.compressPostImage(image);
      data['image'] = await MultipartFile.fromFile(
        uploadImage.path,
        filename: uploadImage.path.split(Platform.pathSeparator).last,
      );
    } else if (uploadImages.isNotEmpty) {
      data['images[]'] = await Future.wait(
        uploadImages.map((selectedImage) async {
          final uploadImage = await _imageCompressor.compressPostImage(
            selectedImage,
          );
          return MultipartFile.fromFile(
            uploadImage.path,
            filename: uploadImage.path.split(Platform.pathSeparator).last,
          );
        }),
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
