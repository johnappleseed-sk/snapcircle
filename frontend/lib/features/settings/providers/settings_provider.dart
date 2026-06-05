import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';
import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  SettingsModel? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  SettingsProvider({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  SettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _settingsRepository.getSettings();
    } on SettingsException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load settings. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(SettingsModel settings) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _settingsRepository.updateSettings(settings);
      return true;
    } on SettingsException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to save settings. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePrivacy({bool? allowMessages, bool? showEmail}) {
    final next = (_settings ?? const SettingsModel()).copyWith(
      allowMessages: allowMessages,
      showEmail: showEmail,
    );
    return updateSettings(next);
  }

  Future<bool> updateNotifications({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? marketingEmailsEnabled,
  }) {
    final next = (_settings ?? const SettingsModel()).copyWith(
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      marketingEmailsEnabled: marketingEmailsEnabled,
    );
    return updateSettings(next);
  }

  Future<bool> deactivateAccount() async {
    return _runAccountAction(_settingsRepository.deactivateAccount);
  }

  Future<bool> deleteAccount() async {
    return _runAccountAction(_settingsRepository.deleteAccount);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAccountAction(Future<void> Function() action) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _settings = (_settings ?? const SettingsModel()).copyWith(
        accountStatus: 'deactivated',
      );
      return true;
    } on SettingsException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update account. Please try again.';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
