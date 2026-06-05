import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';

class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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

  Future<List<PostModel>> getUserPosts(
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
    final posts = _extractPostsJson(response);
    return posts.map(PostModel.fromJson).toList();
  }

  Future<List<UserModel>> getUsers({int page = 1, String? search}) async {
    final queryParameters = <String, dynamic>{'page': page};
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final result = await _apiClient.get(
      ApiEndpoints.users,
      queryParameters: queryParameters,
    );

    return _parseUsersResponse(result.data?.data, result.error);
  }

  Future<List<UserModel>> getFollowers(int userId, {int page = 1}) async {
    final result = await _apiClient.get(
      ApiEndpoints.followers(userId),
      queryParameters: {'page': page},
    );

    return _parseUsersResponse(result.data?.data, result.error);
  }

  Future<List<UserModel>> getFollowing(int userId, {int page = 1}) async {
    final result = await _apiClient.get(
      ApiEndpoints.following(userId),
      queryParameters: {'page': page},
    );

    return _parseUsersResponse(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> followUser(int userId) async {
    final result = await _apiClient.post(ApiEndpoints.followUser(userId));
    return _parseFollowResponse(result.data?.data, result.error);
  }

  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    final result = await _apiClient.delete(ApiEndpoints.unfollowUser(userId));
    return _parseFollowResponse(result.data?.data, result.error);
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
      data['avatar'] = kIsWeb
          ? MultipartFile.fromBytes(
              await avatar.readAsBytes(),
              filename: avatar.name,
            )
          : await MultipartFile.fromFile(
              avatar.path,
              filename: avatar.name.isNotEmpty
                  ? avatar.name
                  : avatar.path.split(Platform.pathSeparator).last,
            );
    }

    if (coverImage != null) {
      data['cover_image'] = kIsWeb
          ? MultipartFile.fromBytes(
              await coverImage.readAsBytes(),
              filename: coverImage.name,
            )
          : await MultipartFile.fromFile(
              coverImage.path,
              filename: coverImage.name.isNotEmpty
                  ? coverImage.name
                  : coverImage.path.split(Platform.pathSeparator).last,
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

  List<UserModel> _parseUsersResponse(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final usersJson = _extractUsersJson(response);
    return usersJson.map(UserModel.fromJson).toList();
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

  List<Map<String, dynamic>> _extractUsersJson(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic> && data['users'] is List) {
      return (data['users'] as List).whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }

    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    throw const ProfileException('Invalid users response from API.');
  }

  List<Map<String, dynamic>> _extractPostsJson(Map<String, dynamic> response) {
    final data = response['data'];
    final posts = data is Map<String, dynamic>
        ? data['posts'] ?? data['data']
        : data;

    if (posts is! List) {
      throw const ProfileException('Invalid user posts response from API.');
    }

    return posts.whereType<Map<String, dynamic>>().toList();
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
