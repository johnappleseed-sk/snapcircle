import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/utils/image_compressor.dart';
import '../models/story_model.dart';

class StoryException implements Exception {
  final String message;

  const StoryException(this.message);

  @override
  String toString() => message;
}

class StoryRepository {
  final ApiClient _apiClient;
  final ImageCompressor _imageCompressor;

  StoryRepository({ApiClient? apiClient, ImageCompressor? imageCompressor})
    : _apiClient = apiClient ?? ApiClient(),
      _imageCompressor = imageCompressor ?? const ImageCompressor();

  Future<PaginatedResponse<StoryModel>> getStories({
    int page = 1,
    int perPage = 15,
    String mode = 'all',
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.stories,
      queryParameters: {'page': page, 'per_page': perPage, 'mode': mode},
    );
    final response = _readResponse(result.data?.data, result.error);
    return PaginatedResponse<StoryModel>.fromApi(
      response: response,
      itemBuilder: StoryModel.fromJson,
      dataKey: 'stories',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<StoryModel> createStory({required File media, String? caption}) async {
    final uploadMedia = await _imageCompressor.compressStoryImage(media);
    final data = <String, dynamic>{
      'media': await MultipartFile.fromFile(
        uploadMedia.path,
        filename: uploadMedia.path.split(Platform.pathSeparator).last,
      ),
    };
    final trimmedCaption = caption?.trim();
    if (trimmedCaption != null && trimmedCaption.isNotEmpty) {
      data['caption'] = trimmedCaption;
    }

    final result = await _apiClient.post(
      ApiEndpoints.stories,
      data: FormData.fromMap(data),
    );

    return _parseStory(result.data?.data, result.error);
  }

  Future<StoryModel> getStory(int storyId) async {
    final result = await _apiClient.get(ApiEndpoints.storyById(storyId));

    return _parseStory(result.data?.data, result.error);
  }

  Future<void> deleteStory(int storyId) async {
    final result = await _apiClient.delete(ApiEndpoints.storyById(storyId));
    if (!result.isSuccess) {
      throw StoryException(result.error ?? 'Unable to delete story.');
    }
  }

  Future<Map<String, dynamic>> markStoryAsViewed(int storyId) async {
    final result = await _apiClient.post(ApiEndpoints.storyView(storyId));
    final response = _readResponse(result.data?.data, result.error);
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const StoryException('Invalid story view response.');
    }

    return data;
  }

  Future<PaginatedResponse<StoryModel>> getUserStories(
    int userId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.userStories(userId),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final response = _readResponse(result.data?.data, result.error);
    return PaginatedResponse<StoryModel>.fromApi(
      response: response,
      itemBuilder: StoryModel.fromJson,
      dataKey: 'stories',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  StoryModel _parseStory(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final data = response['data'];
    final storyJson = data is Map<String, dynamic>
        ? data['story']
        : response['story'];

    if (storyJson is! Map<String, dynamic>) {
      throw const StoryException('Invalid story response.');
    }

    return StoryModel.fromJson(storyJson);
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw StoryException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const StoryException('Invalid response from API.');
    }

    return responseData;
  }

}
