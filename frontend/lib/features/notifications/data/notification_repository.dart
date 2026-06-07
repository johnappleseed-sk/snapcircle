import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../models/notification_model.dart';

class NotificationException implements Exception {
  final String message;

  const NotificationException(this.message);

  @override
  String toString() => message;
}

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<PaginatedResponse<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 15,
    String filter = 'all',
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'per_page': perPage, 'filter': filter},
    );

    final response = _readData(result.data?.data, result.error);
    return PaginatedResponse<NotificationModel>.fromApi(
      response: response,
      itemBuilder: NotificationModel.fromJson,
      dataKey: 'notifications',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<int> getUnreadCount() async {
    final result = await _apiClient.get(ApiEndpoints.notificationUnreadCount);
    final response = _readData(result.data?.data, result.error);
    return _parseInt(response['unread_count']);
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    final result = await _apiClient.put(
      ApiEndpoints.markNotificationRead(notificationId),
    );
    final response = _readData(result.data?.data, result.error);
    final notification = response['notification'];
    if (notification is! Map<String, dynamic>) {
      throw const NotificationException(
        'Invalid notification response from API.',
      );
    }
    return NotificationModel.fromJson(notification);
  }

  Future<int> markAllAsRead() async {
    final result = await _apiClient.put(ApiEndpoints.markAllNotificationsRead);
    final response = _readData(result.data?.data, result.error);
    return _parseInt(response['updated_count']);
  }

  Future<void> deleteNotification(int notificationId) async {
    final result = await _apiClient.delete(
      ApiEndpoints.deleteNotification(notificationId),
    );
    if (!result.isSuccess) {
      throw NotificationException(
        result.error ?? 'Unable to delete notification.',
      );
    }
  }

  Map<String, dynamic> _readData(dynamic responseData, String? error) {
    if (error != null) {
      throw NotificationException(error);
    }
    if (responseData is! Map<String, dynamic>) {
      throw const NotificationException('Invalid response from API.');
    }
    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return responseData;
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
}
