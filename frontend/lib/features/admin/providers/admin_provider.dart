import 'package:flutter/foundation.dart';

import '../../auth/models/user_model.dart';
import '../data/admin_repository.dart';
import '../models/admin_dashboard_model.dart';
import '../models/report_model.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminDashboardModel? _dashboard;
  List<ReportModel> _reports = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminProvider({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  AdminDashboardModel? get dashboard => _dashboard;
  List<ReportModel> get reports => List.unmodifiable(_reports);
  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    await _run(() async => _dashboard = await _repository.getDashboard());
  }

  Future<void> fetchReports({String? status}) async {
    await _run(() async => _reports = await _repository.getReports(status: status));
  }

  Future<bool> updateReportStatus(int reportId, String status) async {
    return _runBool(() async {
      await _repository.updateReportStatus(reportId, status);
      await fetchReports();
    });
  }

  Future<void> fetchUsers({String? search}) async {
    await _run(() async => _users = await _repository.getUsers(search: search));
  }

  Future<bool> banUser(int userId, String reason) async {
    return _runBool(() async {
      await _repository.banUser(userId, reason);
      await fetchUsers();
    });
  }

  Future<bool> unbanUser(int userId) async {
    return _runBool(() async {
      await _repository.unbanUser(userId);
      await fetchUsers();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on AdminException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load admin data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runBool(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AdminException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to complete admin action.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
