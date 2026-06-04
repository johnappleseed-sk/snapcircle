import 'package:flutter/foundation.dart';

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
    : _authRepository = authRepository ?? AuthRepository();

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

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.logout();
    } on AuthException catch (error) {
      _errorMessage = error.message;
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

  Future<bool> _login(Future<AuthResponse> Function() loginAction) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final authResponse = await loginAction();
      _user = authResponse.user;
      _isAuthenticated = true;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
