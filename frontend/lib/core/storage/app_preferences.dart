import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferences {
  static const String _onboardingCompletedKey =
      'snapcircle_onboarding_completed';
  static const String _recentSearchesKey = 'snapcircle_recent_searches';
  static const int _maxRecentSearches = 6;

  final FlutterSecureStorage _storage;

  const AppPreferences({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingCompletedKey);
    return value == 'true';
  }

  Future<void> setOnboardingCompleted(bool completed) {
    return _storage.write(
      key: _onboardingCompletedKey,
      value: completed.toString(),
    );
  }

  Future<List<String>> getRecentSearches() async {
    final raw = await _storage.read(key: _recentSearchesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .take(_maxRecentSearches)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getRecentSearches();
    }

    final current = await getRecentSearches();
    final updated = [
      trimmed,
      ...current.where(
        (value) => value.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(_maxRecentSearches).toList();

    await _storage.write(key: _recentSearchesKey, value: jsonEncode(updated));
    return updated;
  }

  Future<void> clearRecentSearches() {
    return _storage.delete(key: _recentSearchesKey);
  }
}
