import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  bool _isGoogleInitialized = false;

  AuthRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  }) : _tokenStorage = tokenStorage ?? const TokenStorage(),
       _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage),
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  Future<AuthResponse> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthException(
          'Google login is not available on this platform.',
        );
      }

      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final authorization =
          await account.authorizationClient.authorizationForScopes(const [
            'email',
            'profile',
          ]) ??
          await account.authorizationClient.authorizeScopes(const [
            'email',
            'profile',
          ]);
      final accessToken = authorization.accessToken;

      if (accessToken.isEmpty) {
        throw const AuthException('Google access token was missing.');
      }

      return _loginWithSocialToken(
        endpoint: ApiEndpoints.authGoogle,
        accessToken: accessToken,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthException('Google login was cancelled.');
      }

      throw AuthException(
        error.description ?? 'Google login failed. Please try again.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Google login failed. Please try again.');
    }
  }

  Future<AuthResponse> signInWithFacebook() async {
    final result = await _facebookAuth.login(
      permissions: const ['email', 'public_profile'],
      loginTracking: LoginTracking.enabled,
    );

    switch (result.status) {
      case LoginStatus.success:
        final accessToken = result.accessToken?.tokenString;
        if (accessToken == null || accessToken.isEmpty) {
          throw const AuthException('Facebook access token was missing.');
        }

        return _loginWithSocialToken(
          endpoint: ApiEndpoints.authFacebook,
          accessToken: accessToken,
        );
      case LoginStatus.cancelled:
        throw const AuthException('Facebook login was cancelled.');
      case LoginStatus.operationInProgress:
        throw const AuthException('Facebook login is already in progress.');
      case LoginStatus.failed:
        throw AuthException(
          result.message ?? 'Facebook login failed. Please try again.',
        );
    }
  }

  Future<UserModel> getCurrentUser() async {
    final result = await _apiClient.get(ApiEndpoints.user);

    if (!result.isSuccess || result.data == null) {
      throw AuthException(result.error ?? 'Unable to fetch current user.');
    }

    final responseData = result.data!.data;
    final userJson = _extractUserJson(responseData);
    if (userJson == null) {
      throw const AuthException('Invalid current user response from API.');
    }

    return UserModel.fromJson(userJson);
  }

  Future<void> logout() async {
    final hasToken = await _tokenStorage.hasToken();

    if (hasToken) {
      await _apiClient.post(ApiEndpoints.logout);
    }

    await _tokenStorage.deleteToken();
    await _initializeGoogleSignIn();
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
  }

  Future<bool> hasToken() {
    return _tokenStorage.hasToken();
  }

  Future<void> clearToken() {
    return _tokenStorage.deleteToken();
  }

  Future<AuthResponse> _loginWithSocialToken({
    required String endpoint,
    required String accessToken,
  }) async {
    final result = await _apiClient.post(
      endpoint,
      data: {'access_token': accessToken},
    );

    if (!result.isSuccess || result.data == null) {
      throw AuthException(result.error ?? 'Unable to connect to Laravel API.');
    }

    final responseData = result.data!.data;
    if (responseData is! Map<String, dynamic>) {
      throw const AuthException('Invalid login response from API.');
    }

    try {
      final authResponse = AuthResponse.fromJson(responseData);
      await _tokenStorage.saveToken(authResponse.token);
      return authResponse;
    } on FormatException catch (error) {
      throw AuthException(error.message);
    }
  }

  Map<String, dynamic>? _extractUserJson(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (responseData['user'] is Map<String, dynamic>) {
      return responseData['user'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleInitialized = true;
  }
}
