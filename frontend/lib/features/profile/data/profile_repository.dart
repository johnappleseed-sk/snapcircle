import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/utils/image_compressor.dart';
import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';
import '../../stories/models/story_model.dart';

class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}

class ProfileRepository {
  final ApiClient _apiClient;
  final ImageCompressor _imageCompressor;

  ProfileRepository({ApiClient? apiClient, ImageCompressor? imageCompressor})
    : _apiClient = apiClient ?? ApiClient(),
      _imageCompressor = imageCompressor ?? const ImageCompressor();

  Future<UserModel> getProfile() async {
    final result = await _apiClient.get(ApiEndpoints.profile);
    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<UserModel> updateProfile({
    required String name,
    String? username,
    String? bio,
    String? location,
    String? website,
    XFile? avatar,
    XFile? coverImage,
    bool isPrivate = false,
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.profile,
      data: await _buildProfileData(
        name: name,
        username: username,
        bio: bio,
        location: location,
        website: website,
        avatar: avatar,
        coverImage: coverImage,
        isPrivate: isPrivate,
      ),
    );

    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<UserModel> getUserById(int userId) async {
    final result = await _apiClient.get(ApiEndpoints.userById(userId));
    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<UserModel> getUserByUsername(String username) async {
    final result = await _apiClient.get(ApiEndpoints.userByUsername(username));
    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<PaginatedResponse<PostModel>> getUserPosts(
    int userId, {
    int page = 1,
    int perPage = 10,
    String sort = 'latest',
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.userPosts(userId),
      queryParameters: {'page': page, 'per_page': perPage, 'sort': sort},
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

  Future<PaginatedResponse<UserModel>> getUsers({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final result = await _apiClient.get(
      ApiEndpoints.users,
      queryParameters: queryParameters,
    );

    return _parseUsersResponse(
      result.data?.data,
      result.error,
      page: page,
      perPage: perPage,
    );
  }

  Future<PaginatedResponse<UserModel>> getFollowers(
    int userId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.followers(userId),
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return _parseUsersResponse(
      result.data?.data,
      result.error,
      page: page,
      perPage: perPage,
    );
  }

  Future<PaginatedResponse<UserModel>> getFollowing(
    int userId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.following(userId),
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return _parseUsersResponse(
      result.data?.data,
      result.error,
      page: page,
      perPage: perPage,
    );
  }

  Future<PaginatedResponse<UserModel>> getBlockedUsers({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.blocks,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return _parseUsersResponse(
      result.data?.data,
      result.error,
      page: page,
      perPage: perPage,
    );
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

  Future<Map<String, dynamic>> followUser(int userId) async {
    final result = await _apiClient.post(ApiEndpoints.followUser(userId));
    return _parseFollowResponse(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    final result = await _apiClient.delete(ApiEndpoints.unfollowUser(userId));
    return _parseFollowResponse(result.data?.data, result.error);
  }

  Future<PaginatedResponse<UserModel>> getFollowRequests({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.followRequests,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return _parseUsersResponse(
      result.data?.data,
      result.error,
      page: page,
      perPage: perPage,
    );
  }

  Future<void> approveFollowRequest(int userId) async {
    final result = await _apiClient.post(
      ApiEndpoints.approveFollowRequest(userId),
    );
    _readResponse(result.data?.data, result.error);
  }

  Future<void> rejectFollowRequest(int userId) async {
    final result = await _apiClient.post(
      ApiEndpoints.rejectFollowRequest(userId),
    );
    _readResponse(result.data?.data, result.error);
  }

  Future<void> removeFollower(int userId) async {
    final result = await _apiClient.delete(ApiEndpoints.removeFollower(userId));
    _readResponse(result.data?.data, result.error);
  }

  Future<UserModel> blockUser(int userId) async {
    final result = await _apiClient.post(ApiEndpoints.blockUser(userId));
    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<UserModel> unblockUser(int userId) async {
    final result = await _apiClient.delete(ApiEndpoints.unblockUser(userId));
    return _parseUserResponse(result.data?.data, result.error);
  }

  Future<FormData> _buildProfileData({
    required String name,
    String? username,
    String? bio,
    String? location,
    String? website,
    XFile? avatar,
    XFile? coverImage,
    required bool isPrivate,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'username': username?.trim() ?? '',
      'bio': bio?.trim() ?? '',
      'location': location?.trim() ?? '',
      'website': website?.trim() ?? '',
      'is_private': isPrivate ? '1' : '0',
    };

    if (avatar != null) {
      final avatarFile = kIsWeb
          ? null
          : await _imageCompressor.compressAvatar(File(avatar.path));
      data['avatar'] = kIsWeb
          ? MultipartFile.fromBytes(
              await avatar.readAsBytes(),
              filename: avatar.name,
            )
          : await MultipartFile.fromFile(
              avatarFile!.path,
              filename: avatar.name.isNotEmpty
                  ? avatar.name
                  : avatarFile.path.split(Platform.pathSeparator).last,
            );
    }

    if (coverImage != null) {
      final coverFile = kIsWeb
          ? null
          : await _imageCompressor.compressCoverImage(File(coverImage.path));
      data['cover_image'] = kIsWeb
          ? MultipartFile.fromBytes(
              await coverImage.readAsBytes(),
              filename: coverImage.name,
            )
          : await MultipartFile.fromFile(
              coverFile!.path,
              filename: coverImage.name.isNotEmpty
                  ? coverImage.name
                  : coverFile.path.split(Platform.pathSeparator).last,
            );
    }

    return FormData.fromMap(data);
  }

  UserModel _parseUserResponse(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final userJson = _extractUserJson(response);

    if (userJson == null) {
      throw const ProfileException('Invalid user response from API.');
    }

    return UserModel.fromJson(userJson);
  }

  PaginatedResponse<UserModel> _parseUsersResponse(
    dynamic responseData,
    String? error, {
    required int page,
    required int perPage,
  }) {
    final response = _readResponse(responseData, error);
    return PaginatedResponse<UserModel>.fromApi(
      response: response,
      itemBuilder: UserModel.fromJson,
      dataKey: 'users',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Map<String, dynamic> _parseFollowResponse(
    dynamic responseData,
    String? error,
  ) {
    final response = _readResponse(responseData, error);
    final data = response['data'];
    final source = data is Map<String, dynamic> ? data : response;

    return {
      if (source.containsKey('followers_count'))
        'followers_count': _parseInt(source['followers_count']),
      if (source.containsKey('following_count'))
        'following_count': _parseInt(source['following_count']),
      if (source.containsKey('is_followed_by_me'))
        'is_followed_by_me': _parseBool(source['is_followed_by_me']),
      if (source.containsKey('has_requested_follow'))
        'has_requested_follow': _parseBool(source['has_requested_follow']),
      if (source.containsKey('follow_status'))
        'follow_status': source['follow_status']?.toString(),
    };
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw ProfileException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const ProfileException('Invalid response from API.');
    }

    return responseData;
  }

  Map<String, dynamic>? _extractUserJson(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (response['user'] is Map<String, dynamic>) {
      return response['user'] as Map<String, dynamic>;
    }

    return null;
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
