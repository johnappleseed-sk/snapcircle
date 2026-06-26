import 'package:flutter/foundation.dart';

import '../../auth/models/user_model.dart';
import '../../comments/models/comment_model.dart';
import '../../feed/models/post_model.dart';
import '../data/admin_repository.dart';
import '../models/admin_dashboard_model.dart';
import '../models/report_model.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminDashboardModel? _dashboard;
  List<ReportModel> _reports = [];
  ReportModel? _selectedReport;
  UserModel? _selectedUser;
  List<UserModel> _users = [];
  List<PostModel> _posts = [];
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMoreUsers = false;
  bool _isLoadingMorePosts = false;
  bool _isLoadingMoreComments = false;
  int _usersPage = 1;
  int _usersLastPage = 1;
  int _postsPage = 1;
  int _postsLastPage = 1;
  int _commentsPage = 1;
  int _commentsLastPage = 1;
  final int _perPage = 15;
  String? _userSearch;
  String _userRoleFilter = 'all';
  String _userStatusFilter = 'all';
  String? _postSearch;
  String _postStatusFilter = 'all';
  String? _commentSearch;
  String _commentStatusFilter = 'all';
  String? _errorMessage;

  AdminProvider({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  AdminDashboardModel? get dashboard => _dashboard;
  List<ReportModel> get reports => List.unmodifiable(_reports);
  ReportModel? get selectedReport => _selectedReport;
  UserModel? get selectedUser => _selectedUser;
  List<UserModel> get users => List.unmodifiable(_users);
  List<PostModel> get posts => List.unmodifiable(_posts);
  List<CommentModel> get comments => List.unmodifiable(_comments);
  bool get isLoading => _isLoading;
  bool get isLoadingMoreUsers => _isLoadingMoreUsers;
  bool get isLoadingMorePosts => _isLoadingMorePosts;
  bool get isLoadingMoreComments => _isLoadingMoreComments;
  bool get hasMoreUsers => _usersPage < _usersLastPage;
  bool get hasMorePosts => _postsPage < _postsLastPage;
  bool get hasMoreComments => _commentsPage < _commentsLastPage;
  String? get userSearch => _userSearch;
  String get userRoleFilter => _userRoleFilter;
  String get userStatusFilter => _userStatusFilter;
  String? get postSearch => _postSearch;
  String get postStatusFilter => _postStatusFilter;
  String? get commentSearch => _commentSearch;
  String get commentStatusFilter => _commentStatusFilter;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    await _run(() async => _dashboard = await _repository.getDashboard());
  }

  Future<void> fetchReports({String? status}) async {
    await _run(
      () async => _reports = await _repository.getReports(status: status),
    );
  }

  Future<void> fetchReport(int reportId) async {
    await _run(
      () async => _selectedReport = await _repository.getReport(reportId),
    );
  }

  Future<bool> updateReportStatus(int reportId, String status) async {
    return _runBool(() async {
      await _repository.updateReportStatus(reportId, status);
      if (_selectedReport?.id == reportId) {
        _selectedReport = await _repository.getReport(reportId);
      }
      await fetchReports();
    });
  }

  Future<void> fetchUsers({
    String? search,
    String? role,
    String? accountStatus,
  }) async {
    _userSearch = search?.trim().isEmpty ?? true ? null : search?.trim();
    _userRoleFilter = role ?? _userRoleFilter;
    _userStatusFilter = accountStatus ?? _userStatusFilter;
    _usersPage = 1;

    await _run(() async {
      final response = await _repository.getUsersPage(
        page: _usersPage,
        search: _userSearch,
        role: _userRoleFilter,
        accountStatus: _userStatusFilter,
        perPage: _perPage,
      );
      _users = response.items;
      _usersPage = response.currentPage;
      _usersLastPage = response.lastPage;
    });
  }

  Future<void> loadMoreUsers() async {
    if (_isLoading || _isLoadingMoreUsers || !hasMoreUsers) {
      return;
    }

    _isLoadingMoreUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getUsersPage(
        page: _usersPage + 1,
        search: _userSearch,
        role: _userRoleFilter,
        accountStatus: _userStatusFilter,
        perPage: _perPage,
      );
      _users = _mergeById(_users, response.items, (user) => user.id);
      _usersPage = response.currentPage;
      _usersLastPage = response.lastPage;
    } on AdminException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more users.';
    } finally {
      _isLoadingMoreUsers = false;
      notifyListeners();
    }
  }

  Future<void> fetchUser(int userId) async {
    await _run(() async => _selectedUser = await _repository.getUser(userId));
  }

  Future<bool> banUser(int userId, String reason) async {
    return _runBool(() async {
      await _repository.banUser(userId, reason);
      await fetchUsers(
        search: _userSearch,
        role: _userRoleFilter,
        accountStatus: _userStatusFilter,
      );
      if (_selectedUser?.id == userId) {
        _selectedUser = await _repository.getUser(userId);
      }
    });
  }

  Future<bool> unbanUser(int userId) async {
    return _runBool(() async {
      await _repository.unbanUser(userId);
      await fetchUsers(
        search: _userSearch,
        role: _userRoleFilter,
        accountStatus: _userStatusFilter,
      );
      if (_selectedUser?.id == userId) {
        _selectedUser = await _repository.getUser(userId);
      }
    });
  }

  Future<bool> updateUserRole(int userId, String role) async {
    return _runBool(() async {
      await _repository.updateUserRole(userId, role);
      await fetchUsers(
        search: _userSearch,
        role: _userRoleFilter,
        accountStatus: _userStatusFilter,
      );
      if (_selectedUser?.id == userId) {
        _selectedUser = await _repository.getUser(userId);
      }
    });
  }

  Future<void> fetchPosts({String? search, String? status}) async {
    _postSearch = search?.trim().isEmpty ?? true ? null : search?.trim();
    _postStatusFilter = status ?? _postStatusFilter;
    _postsPage = 1;

    await _run(() async {
      final response = await _repository.getPostsPage(
        page: _postsPage,
        search: _postSearch,
        status: _postStatusFilter,
        perPage: _perPage,
      );
      _posts = response.items;
      _postsPage = response.currentPage;
      _postsLastPage = response.lastPage;
    });
  }

  Future<void> loadMorePosts() async {
    if (_isLoading || _isLoadingMorePosts || !hasMorePosts) {
      return;
    }

    _isLoadingMorePosts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getPostsPage(
        page: _postsPage + 1,
        search: _postSearch,
        status: _postStatusFilter,
        perPage: _perPage,
      );
      _posts = _mergeById(_posts, response.items, (post) => post.id);
      _postsPage = response.currentPage;
      _postsLastPage = response.lastPage;
    } on AdminException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more posts.';
    } finally {
      _isLoadingMorePosts = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(int postId) async {
    return _runBool(() async {
      await _repository.deletePost(postId);
      _posts = _posts.where((post) => post.id != postId).toList();
      _dashboard = await _repository.getDashboard();
    });
  }

  Future<void> fetchComments({String? search, String? status}) async {
    _commentSearch = search?.trim().isEmpty ?? true ? null : search?.trim();
    _commentStatusFilter = status ?? _commentStatusFilter;
    _commentsPage = 1;

    await _run(() async {
      final response = await _repository.getCommentsPage(
        page: _commentsPage,
        search: _commentSearch,
        status: _commentStatusFilter,
        perPage: _perPage,
      );
      _comments = response.items;
      _commentsPage = response.currentPage;
      _commentsLastPage = response.lastPage;
    });
  }

  Future<void> loadMoreComments() async {
    if (_isLoading || _isLoadingMoreComments || !hasMoreComments) {
      return;
    }

    _isLoadingMoreComments = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getCommentsPage(
        page: _commentsPage + 1,
        search: _commentSearch,
        status: _commentStatusFilter,
        perPage: _perPage,
      );
      _comments = _mergeById(
        _comments,
        response.items,
        (comment) => comment.id,
      );
      _commentsPage = response.currentPage;
      _commentsLastPage = response.lastPage;
    } on AdminException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more comments.';
    } finally {
      _isLoadingMoreComments = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(int commentId) async {
    return _runBool(() async {
      await _repository.deleteComment(commentId);
      _comments = _comments
          .where((comment) => comment.id != commentId)
          .toList();
      _dashboard = await _repository.getDashboard();
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

  List<T> _mergeById<T>(
    List<T> current,
    List<T> incoming,
    int Function(T item) idOf,
  ) {
    final seen = current.map(idOf).toSet();
    return [...current, ...incoming.where((item) => seen.add(idOf(item)))];
  }
}
