import 'package:flutter/foundation.dart';

import '../../auth/models/user_model.dart';
import '../../profile/data/profile_repository.dart';

class UsersProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  List<UserModel> _users = [];
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 15;
  String? _searchQuery;
  String? _errorMessage;

  UsersProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository();

  List<UserModel> get users => List.unmodifiable(_users);
  List<UserModel> get followers => List.unmodifiable(_followers);
  List<UserModel> get following => List.unmodifiable(_following);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers({bool refresh = false, String? search}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || search != _searchQuery) {
      _currentPage = 1;
      _hasMore = true;
    }

    _searchQuery = search;
    _isLoading = refresh || _users.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getUsers(
        page: _currentPage,
        perPage: _perPage,
        search: _searchQuery,
      );
      _users = response.items;
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load users. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreUsers() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _profileRepository.getUsers(
        page: nextPage,
        perPage: _perPage,
        search: _searchQuery,
      );

      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        _users = _mergeUsers(_users, response.items);
        _hasMore = response.hasMore;
      }
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more users. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchFollowers(int userId, {bool refresh = false}) async {
    await _fetchFollowList(userId, refresh: refresh, isFollowers: true);
  }

  Future<void> fetchFollowing(int userId, {bool refresh = false}) async {
    await _fetchFollowList(userId, refresh: refresh, isFollowers: false);
  }

  Future<void> loadMoreFollowers(int userId) async {
    await _loadMoreFollowList(userId, isFollowers: true);
  }

  Future<void> loadMoreFollowing(int userId) async {
    await _loadMoreFollowList(userId, isFollowers: false);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _fetchFollowList(
    int userId, {
    required bool refresh,
    required bool isFollowers,
  }) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    final targetList = isFollowers ? _followers : _following;
    _isLoading = refresh || targetList.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = isFollowers
          ? await _profileRepository.getFollowers(
              userId,
              page: _currentPage,
              perPage: _perPage,
            )
          : await _profileRepository.getFollowing(
              userId,
              page: _currentPage,
              perPage: _perPage,
            );

      if (isFollowers) {
        _followers = response.items;
      } else {
        _following = response.items;
      }
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load users. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreFollowList(
    int userId, {
    required bool isFollowers,
  }) async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = isFollowers
          ? await _profileRepository.getFollowers(
              userId,
              page: nextPage,
              perPage: _perPage,
            )
          : await _profileRepository.getFollowing(
              userId,
              page: nextPage,
              perPage: _perPage,
            );

      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        if (isFollowers) {
          _followers = _mergeUsers(_followers, response.items);
        } else {
          _following = _mergeUsers(_following, response.items);
        }
        _hasMore = response.hasMore;
      }
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more users. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  List<UserModel> _mergeUsers(List<UserModel> current, List<UserModel> next) {
    final seenIds = current.map((user) => user.id).toSet();
    return [...current, ...next.where((user) => seenIds.add(user.id))];
  }
}
