import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/activity_model.dart';

class ActivityException implements Exception {
  final String message;

  const ActivityException(this.message);

  @override
  String toString() => message;
}

class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ActivityModel> getActivity({int limit = 10}) async {
    final result = await _apiClient.get(
      ApiEndpoints.myActivity,
      queryParameters: {'per_page': limit},
    );

    if (result.error != null) {
      throw ActivityException(result.error!);
    }

    final response = result.data?.data;
    if (response is! Map<String, dynamic>) {
      throw const ActivityException('Invalid activity response from API.');
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return ActivityModel.fromJson(data);
    }

    return ActivityModel.fromJson(response);
  }
}
