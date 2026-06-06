import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/models/user_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/report_model.dart';

class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AdminDashboardModel> getDashboard() async {
    final result = await _apiClient.get(ApiEndpoints.adminDashboard);
    final response = _read(result.data?.data, result.error);
    final data = response['data'];
    return AdminDashboardModel.fromJson(
      data is Map<String, dynamic> ? data : response,
    );
  }

  Future<List<ReportModel>> getReports({int page = 1, String? status}) async {
    final result = await _apiClient.get(
      ApiEndpoints.adminReports,
      queryParameters: {
        'page': page,
        if (status != null && status != 'all') 'status': status,
      },
    );
    final response = _read(result.data?.data, result.error);
    final reports = _list(response, 'reports');
    return reports.map(ReportModel.fromJson).toList();
  }

  Future<void> updateReportStatus(
    int reportId,
    String status, {
    String? actionTaken,
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.adminReportStatus(reportId),
      data: {
        'status': status,
        if (actionTaken != null && actionTaken.trim().isNotEmpty)
          'action_taken': actionTaken.trim(),
      },
    );
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to update report.');
    }
  }

  Future<List<UserModel>> getUsers({
    int page = 1,
    String? search,
    String? role,
    String? accountStatus,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role != 'all') 'role': role,
        if (accountStatus != null && accountStatus != 'all')
          'account_status': accountStatus,
      },
    );
    final response = _read(result.data?.data, result.error);
    final users = _list(response, 'users');
    return users.map(UserModel.fromJson).toList();
  }

  Future<void> banUser(int userId, String reason) async {
    final result = await _apiClient.put(
      ApiEndpoints.adminUserBan(userId),
      data: {'reason': reason},
    );
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to ban user.');
    }
  }

  Future<void> unbanUser(int userId) async {
    final result = await _apiClient.put(ApiEndpoints.adminUserUnban(userId));
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to unban user.');
    }
  }

  Map<String, dynamic> _read(dynamic responseData, String? error) {
    if (error != null) throw AdminException(error);
    if (responseData is! Map<String, dynamic>) {
      throw const AdminException('Invalid admin response from API.');
    }
    return responseData;
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> response, String key) {
    final data = response['data'];
    final list = data is Map<String, dynamic> && data[key] is List
        ? data[key]
        : response[key] is List
        ? response[key]
        : null;

    if (list is! List) {
      throw const AdminException('Invalid admin list response.');
    }

    return list.whereType<Map<String, dynamic>>().toList();
  }
}
