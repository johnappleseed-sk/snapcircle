import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/settings_model.dart';

class SettingsException implements Exception {
  final String message;

  const SettingsException(this.message);

  @override
  String toString() => message;
}

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<SettingsModel> getSettings() async {
    final result = await _apiClient.get(ApiEndpoints.settings);
    return _parseSettingsResponse(result.data?.data, result.error);
  }

  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final result = await _apiClient.put(
      ApiEndpoints.settings,
      data: settings.toSettingsUpdateJson(),
    );
    return _parseSettingsResponse(result.data?.data, result.error);
  }

  Future<SettingsModel> updatePrivacySetting({required bool isPrivate}) async {
    final result = await _apiClient.put(
      ApiEndpoints.privacySettings,
      data: {'is_private': isPrivate},
    );
    return _parseSettingsResponse(result.data?.data, result.error);
  }

  Future<void> deactivateAccount() async {
    final result = await _apiClient.put(ApiEndpoints.deactivateAccount);
    _throwIfError(result.error);
  }

  Future<void> deleteAccount() async {
    final result = await _apiClient.delete(ApiEndpoints.deleteAccount);
    _throwIfError(result.error);
  }

  SettingsModel _parseSettingsResponse(dynamic responseData, String? error) {
    _throwIfError(error);

    if (responseData is! Map<String, dynamic>) {
      throw const SettingsException('Invalid settings response from API.');
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic> &&
        data['settings'] is Map<String, dynamic>) {
      return SettingsModel.fromJson(data['settings'] as Map<String, dynamic>);
    }

    if (data is Map<String, dynamic>) {
      return SettingsModel.fromJson(data);
    }

    if (responseData['settings'] is Map<String, dynamic>) {
      return SettingsModel.fromJson(
        responseData['settings'] as Map<String, dynamic>,
      );
    }

    throw const SettingsException('Invalid settings response from API.');
  }

  void _throwIfError(String? error) {
    if (error != null) {
      throw SettingsException(error);
    }
  }
}
