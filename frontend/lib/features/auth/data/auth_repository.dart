import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const String _googleWebClientId =
      '928234105384-54ji20nah7j584dq06jub54t56jrlmg2.apps.googleusercontent.com';

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  bool _isGoogleInitialized = false;
  String? _phoneVerificationId;
  ConfirmationResult? _phoneConfirmationResult;

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
    try {
      await _initializeGoogleSignIn();

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          provider,
        );
        final accessToken = userCredential.credential?.accessToken;

        if (accessToken == null || accessToken.isEmpty) {
          throw const AuthException('Google access token was missing.');
        }

        return _loginWithSocialToken(
          endpoint: ApiEndpoints.authGoogle,
          accessToken: accessToken,
        );
      }

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

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: account.authentication.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

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
    if (kIsWeb) {
      final provider = FacebookAuthProvider()
        ..addScope('email')
        ..addScope('public_profile');
      final userCredential = await FirebaseAuth.instance.signInWithPopup(
        provider,
      );

      final accessToken = userCredential.credential?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthException('Facebook access token was missing.');
      }

      return _loginWithSocialToken(
        endpoint: ApiEndpoints.authFacebook,
        accessToken: accessToken,
      );
    }

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

  Future<AuthResponse> signInWithDemo() {
    return _loginWithSocialToken(
      endpoint: ApiEndpoints.authDemo,
      accessToken: 'local-demo-login',
    );
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    final normalizedPhone = phoneNumber.trim();

    if (!normalizedPhone.startsWith('+')) {
      throw const AuthException(
        'Enter the phone number with country code, for example +16505553434.',
      );
    }

    try {
      if (kIsWeb) {
        _phoneConfirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(normalizedPhone);
        return;
      }

      final completer = Completer<void>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException(_firebaseAuthMessage(error)));
          }
        },
        codeSent: (verificationId, _) {
          _phoneVerificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _phoneVerificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthMessage(error));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Unable to send OTP. Please try again.');
    }
  }

  Future<AuthResponse> verifyPhoneOtp(String smsCode) async {
    final normalizedCode = smsCode.trim();

    if (normalizedCode.length < 4) {
      throw const AuthException('Enter the verification code from SMS.');
    }

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final confirmationResult = _phoneConfirmationResult;
        if (confirmationResult == null) {
          throw const AuthException('Request a new OTP before verifying.');
        }
        userCredential = await confirmationResult.confirm(normalizedCode);
      } else {
        final verificationId = _phoneVerificationId;
        if (verificationId == null || verificationId.isEmpty) {
          throw const AuthException('Request a new OTP before verifying.');
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: normalizedCode,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Firebase ID token was missing.');
      }

      return _loginWithCredentials(
        endpoint: ApiEndpoints.authPhone,
        data: {'id_token': idToken},
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthMessage(error));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('OTP verification failed. Please try again.');
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _loginWithCredentials(
      endpoint: ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
  }

  Future<AuthResponse> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    return _loginWithCredentials(
      endpoint: ApiEndpoints.authRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<String> forgotPassword(String email) async {
    final result = await _apiClient.post(
      ApiEndpoints.authForgotPassword,
      data: {'email': email},
    );

    if (!result.isSuccess || result.data == null) {
      throw AuthException(result.error ?? 'Unable to request a reset email.');
    }

    return _messageFromResponse(
      result.data!.data,
      fallback: 'Password reset instructions were sent if the email exists.',
    );
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.authResetPassword,
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': password,
      },
    );

    if (!result.isSuccess || result.data == null) {
      throw AuthException(result.error ?? 'Unable to reset password.');
    }

    return _messageFromResponse(
      result.data!.data,
      fallback: 'Password reset successful.',
    );
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
    await FirebaseAuth.instance.signOut();
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
    return _loginWithCredentials(
      endpoint: endpoint,
      data: {'access_token': accessToken},
    );
  }

  Future<AuthResponse> _loginWithCredentials({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    final result = await _apiClient.post(endpoint, data: data);

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

  String _messageFromResponse(
    dynamic responseData, {
    required String fallback,
  }) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
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

    await _googleSignIn.initialize(
      clientId: kIsWeb ? _googleWebClientId : null,
    );
    _isGoogleInitialized = true;
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code.';
      case 'too-many-requests':
        return 'Too many OTP attempts. Please wait before trying again.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect.';
      case 'session-expired':
      case 'code-expired':
        return 'The verification code expired. Request a new OTP.';
      case 'captcha-check-failed':
        return 'reCAPTCHA failed. Refresh and try again.';
      case 'quota-exceeded':
        return 'SMS quota has been exceeded for this Firebase project.';
      default:
        return error.message ?? 'Firebase authentication failed.';
    }
  }
}
