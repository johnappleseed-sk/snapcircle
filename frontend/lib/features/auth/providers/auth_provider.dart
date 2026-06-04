import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final TokenStorage _tokenStorage;

  bool _isAuthenticated = false;
  bool _isLoading = false;

  AuthProvider({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? const TokenStorage();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _tokenStorage.hasToken();
    _isLoading = false;
    notifyListeners();
  }
}
