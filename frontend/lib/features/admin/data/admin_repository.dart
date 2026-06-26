import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/paginated_response.dart';
import '../../auth/models/user_model.dart';
import '../../comments/models/comment_model.dart';
import '../../feed/models/post_model.dart';
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

  AdminRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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
    return PaginatedResponse<ReportModel>.fromApi(
      response: response,
      itemBuilder: ReportModel.fromJson,
      dataKey: 'reports',
      fallbackPage: page,
      fallbackPerPage: 15,
    ).items;
  }

  Future<ReportModel> getReport(int reportId) async {
    final result = await _apiClient.get(ApiEndpoints.adminReportById(reportId));
    final response = _read(result.data?.data, result.error);
    final data = response['data'];
    final source = data is Map<String, dynamic> ? data : response;
    final report = source['report'];

    if (report is! Map<String, dynamic>) {
      throw const AdminException('Invalid report response from API.');
    }

    return ReportModel.fromJson(report);
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

  Future<PaginatedResponse<UserModel>> getUsersPage({
    int page = 1,
    String? search,
    String? role,
    String? accountStatus,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role != 'all') 'role': role,
        if (accountStatus != null && accountStatus != 'all')
          'account_status': accountStatus,
      },
    );
    final response = _read(result.data?.data, result.error);
    return PaginatedResponse<UserModel>.fromApi(
      response: response,
      itemBuilder: UserModel.fromJson,
      dataKey: 'users',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<List<UserModel>> getUsers({
    int page = 1,
    String? search,
    String? role,
    String? accountStatus,
  }) async {
    return (await getUsersPage(
      page: page,
      search: search,
      role: role,
      accountStatus: accountStatus,
    )).items;
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

  Future<void> updateUserRole(int userId, String role) async {
    final result = await _apiClient.put(
      ApiEndpoints.adminUserRole(userId),
      data: {'role': role},
    );
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to update user role.');
    }
  }

  Future<UserModel> getUser(int userId) async {
    final result = await _apiClient.get(ApiEndpoints.adminUserById(userId));
    final response = _read(result.data?.data, result.error);
    final data = response['data'];
    final source = data is Map<String, dynamic> ? data : response;
    final user = source['user'];

    if (user is! Map<String, dynamic>) {
      throw const AdminException('Invalid admin user response from API.');
    }

    return UserModel.fromJson(user);
  }

  Future<PaginatedResponse<PostModel>> getPostsPage({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.adminPosts,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final response = _read(result.data?.data, result.error);
    return PaginatedResponse<PostModel>.fromApi(
      response: response,
      itemBuilder: PostModel.fromJson,
      dataKey: 'posts',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<List<PostModel>> getPosts({int page = 1}) async {
    return (await getPostsPage(page: page)).items;
  }

  Future<void> deletePost(int postId) async {
    final result = await _apiClient.delete(ApiEndpoints.adminPostById(postId));
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to delete post.');
    }
  }

  Future<PaginatedResponse<CommentModel>> getCommentsPage({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.adminComments,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final response = _read(result.data?.data, result.error);
    return PaginatedResponse<CommentModel>.fromApi(
      response: response,
      itemBuilder: CommentModel.fromJson,
      dataKey: 'comments',
      fallbackPage: page,
      fallbackPerPage: perPage,
    );
  }

  Future<List<CommentModel>> getComments({int page = 1}) async {
    return (await getCommentsPage(page: page)).items;
  }

  Future<void> deleteComment(int commentId) async {
    final result = await _apiClient.delete(
      ApiEndpoints.adminCommentById(commentId),
    );
    if (!result.isSuccess) {
      throw AdminException(result.error ?? 'Unable to delete comment.');
    }
  }

  Map<String, dynamic> _read(dynamic responseData, String? error) {
    if (error != null) throw AdminException(error);
    if (responseData is! Map<String, dynamic>) {
      throw const AdminException('Invalid admin response from API.');
    }
    return responseData;
  }
}
