import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../data/auth_repository.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    ApiClient.unauthorizedEvents.addListener(_handleUnauthorizedEvent);
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _errorMessage = null;

    final hasToken = await _authRepository.hasToken();
    if (!hasToken) {
      _clearSession();
      _setLoading(false);
      return;
    }

    try {
      _user = await _authRepository.getCurrentUser();
      _isAuthenticated = true;
      await PushNotificationService.instance.registerDeviceToken();
    } on AuthException catch (error) {
      await _authRepository.clearToken();
      _clearSession();
      _errorMessage = error.message;
    } catch (_) {
      await _authRepository.clearToken();
      _clearSession();
      _errorMessage = 'Your session expired. Please log in again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    return _login(() => _authRepository.signInWithGoogle());
  }

  Future<bool> loginWithFacebook() async {
    return _login(() => _authRepository.signInWithFacebook());
  }

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.sendPhoneOtp(phoneNumber);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to send OTP. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPhoneOtp(String smsCode) async {
    return _login(() => _authRepository.verifyPhoneOtp(smsCode));
  }

  Future<bool> loginWithDemo() async {
    return _login(() => _authRepository.signInWithDemo());
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _login(
      () => _authRepository.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    return _login(
      () => _authRepository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await _authRepository.forgotPassword(email);
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Password reset request failed. Please try again.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await _authRepository.resetPassword(
        email: email,
        token: token,
        password: password,
      );
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Password reset failed. Please try again.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await PushNotificationService.instance.unregisterDeviceToken();
      await _authRepository.logout();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      await _authRepository.clearToken();
    } catch (_) {
      _errorMessage = 'Logout failed. Local session was cleared.';
      await _authRepository.clearToken();
    } finally {
      _clearSession();
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    ApiClient.unauthorizedEvents.removeListener(_handleUnauthorizedEvent);
    super.dispose();
  }

  Future<bool> _login(Future<AuthResponse> Function() loginAction) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final authResponse = await loginAction();
      _user = authResponse.user;
      _isAuthenticated = true;
      await PushNotificationService.instance.registerDeviceToken();
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _clearSession();
      return false;
    } catch (_) {
      _errorMessage = 'Login failed. Please try again.';
      _clearSession();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _clearSession() {
    _user = null;
    _isAuthenticated = false;
  }

  void _handleUnauthorizedEvent() {
    if (!_isAuthenticated) {
      return;
    }

    _clearSession();
    _errorMessage = 'Your session expired. Please log in again.';
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
