import 'package:flutter/foundation.dart';

import '../../../core/storage/app_preferences.dart';
import '../../../core/utils/hashtag_utils.dart';
import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';
import '../../profile/data/profile_repository.dart';
import '../data/explore_repository.dart';
import '../models/trending_tag_model.dart';

class ExploreProvider extends ChangeNotifier {
  final ExploreRepository _exploreRepository;
  final ProfileRepository _profileRepository;
  final AppPreferences _preferences;

  List<PostModel> _explorePosts = [];
  List<PostModel> _trendingPosts = [];
  List<TrendingTagModel> _trendingTags = [];
  List<UserModel> _recommendedUsers = [];
  List<UserModel> _exploreUsers = [];
  bool _isLoading = false;
  bool _isLoadingPosts = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _hasMorePosts = true;
  int _currentPostPage = 1;
  final int _perPage = 12;
  String _currentSort = 'latest';
  String _searchQuery = '';
  String? _selectedTag;
  String? _errorMessage;
  final Set<int> _followingUserIds = {};
  List<String> _recentSearches = [];
  int _searchGeneration = 0;

  ExploreProvider({
    ExploreRepository? exploreRepository,
    ProfileRepository? profileRepository,
    AppPreferences? preferences,
  }) : _exploreRepository = exploreRepository ?? ExploreRepository(),
       _profileRepository = profileRepository ?? ProfileRepository(),
       _preferences = preferences ?? const AppPreferences() {
    loadRecentSearches();
  }

  List<PostModel> get explorePosts => List.unmodifiable(_explorePosts);
  List<PostModel> get trendingPosts => List.unmodifiable(_trendingPosts);
  List<TrendingTagModel> get trendingTags => List.unmodifiable(_trendingTags);
  List<UserModel> get recommendedUsers => List.unmodifiable(_recommendedUsers);
  List<UserModel> get exploreUsers => List.unmodifiable(_exploreUsers);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get hasMorePosts => _hasMorePosts;
  int get currentPostPage => _currentPostPage;
  String get currentSort => _currentSort;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  String? get errorMessage => _errorMessage;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool isFollowingUser(int userId) => _followingUserIds.contains(userId);

  Future<void> loadRecentSearches() async {
    _recentSearches = await _preferences.getRecentSearches();
    notifyListeners();
  }

  Future<void> fetchExploreData({bool refresh = false}) async {
    if (_isLoading || _isSearching) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final errors = <String>[];

    await Future.wait([
      _loadExploreSlice(
        () => fetchRecommendedUsers(refresh: true, notify: false),
        errors,
      ),
      _loadExploreSlice(
        () => fetchTrendingPosts(refresh: true, notify: false),
        errors,
      ),
      _loadExploreSlice(
        () => fetchTrendingTags(refresh: true, notify: false),
        errors,
      ),
      _loadExploreSlice(
        () => fetchExplorePosts(refresh: true, notify: false),
        errors,
      ),
    ]);

    if (errors.isNotEmpty && _explorePosts.isEmpty) {
      _errorMessage = errors.first;
    } else if (errors.isNotEmpty) {
      _errorMessage = 'Some explore content could not be refreshed.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadExploreSlice(
    Future<void> Function() load,
    List<String> errors,
  ) async {
    try {
      await load();
    } on ExploreException catch (error) {
      errors.add(error.message);
    } catch (_) {
      errors.add('Unable to load explore content.');
    }
  }

  Future<void> fetchExplorePosts({
    bool refresh = false,
    bool notify = true,
  }) async {
    if (_isLoadingPosts || _isLoadingMore) return;

    if (refresh) {
      _currentPostPage = 1;
      _hasMorePosts = true;
    }

    _isLoadingPosts = true;
    if (notify) {
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final posts = _selectedTag == null
          ? await _exploreRepository.getExplorePosts(
              page: _currentPostPage,
              perPage: _perPage,
              search: _searchQuery.isEmpty ? null : _searchQuery,
              sort: _currentSort,
            )
          : await _exploreRepository.getPostsByTag(
              tag: _selectedTag!,
              page: _currentPostPage,
              perPage: _perPage,
              sort: _currentSort,
            );
      _explorePosts = posts;
      _hasMorePosts = posts.length >= _perPage;
    } finally {
      _isLoadingPosts = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> fetchTrendingPosts({
    bool refresh = false,
    bool notify = true,
  }) async {
    _trendingPosts = await _exploreRepository.getTrendingPosts();
    if (notify) notifyListeners();
  }

  Future<void> fetchTrendingTags({
    bool refresh = false,
    bool notify = true,
  }) async {
    _trendingTags = await _exploreRepository.getTrendingTags();
    if (notify) notifyListeners();
  }

  Future<void> fetchRecommendedUsers({
    bool refresh = false,
    bool notify = true,
  }) async {
    _recommendedUsers = await _exploreRepository.getRecommendedUsers();
    if (notify) notifyListeners();
  }

  Future<void> searchExplore(String query) async {
    final trimmed = query.trim();
    if (trimmed == _searchQuery && !_isSearching) {
      return;
    }

    final generation = ++_searchGeneration;
    _searchQuery = trimmed;
    _selectedTag = null;

    if (trimmed.isEmpty) {
      _exploreUsers = [];
      await fetchExplorePosts(refresh: true);
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _exploreRepository.globalSearch(query: trimmed);
      if (generation != _searchGeneration) {
        return;
      }
      _explorePosts = results['posts'] is List<PostModel>
          ? results['posts'] as List<PostModel>
          : [];
      _exploreUsers = results['users'] is List<UserModel>
          ? results['users'] as List<UserModel>
          : [];
      _recentSearches = await _preferences.addRecentSearch(trimmed);
      _hasMorePosts = false;
    } on ExploreException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to search Explore.';
    } finally {
      if (generation == _searchGeneration) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> changeSort(String sort) async {
    if (_currentSort == sort) {
      return;
    }

    _currentSort = sort;
    await fetchExplorePosts(refresh: true);
  }

  Future<void> selectTag(TrendingTagModel tag) async {
    await selectTagName(tag.tag);
  }

  Future<void> selectTagName(String tag) async {
    final normalizedTag = HashtagUtils.normalize(tag);
    if (normalizedTag.isEmpty || _selectedTag == normalizedTag) {
      return;
    }

    _searchGeneration += 1;
    _selectedTag = normalizedTag;
    _searchQuery = '';
    _exploreUsers = [];
    _isSearching = false;
    await fetchExplorePosts(refresh: true);
  }

  Future<void> openTag(String tag) async {
    final normalizedTag = HashtagUtils.normalize(tag);
    if (normalizedTag.isEmpty) {
      return;
    }

    if (_selectedTag == normalizedTag && _explorePosts.isNotEmpty) {
      return;
    }

    _searchGeneration += 1;
    _selectedTag = normalizedTag;
    _searchQuery = '';
    _exploreUsers = [];
    _isSearching = false;
    await fetchExploreData(refresh: true);
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _searchQuery.isNotEmpty) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPostPage + 1;
      final posts = _selectedTag == null
          ? await _exploreRepository.getExplorePosts(
              page: nextPage,
              perPage: _perPage,
              sort: _currentSort,
            )
          : await _exploreRepository.getPostsByTag(
              tag: _selectedTag!,
              page: nextPage,
              perPage: _perPage,
              sort: _currentSort,
            );
      if (posts.isEmpty) {
        _hasMorePosts = false;
      } else {
        _currentPostPage = nextPage;
        _explorePosts = [..._explorePosts, ...posts];
        _hasMorePosts = posts.length >= _perPage;
      }
    } on ExploreException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more explore posts.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> clearSearch() async {
    if (_searchQuery.isEmpty && _selectedTag == null) return;
    _searchGeneration += 1;
    _searchQuery = '';
    _selectedTag = null;
    _exploreUsers = [];
    _isSearching = false;
    await fetchExplorePosts(refresh: true);
  }

  Future<void> clearRecentSearches() async {
    await _preferences.clearRecentSearches();
    _recentSearches = [];
    notifyListeners();
  }

  Future<void> toggleFollow(UserModel user) async {
    if (_followingUserIds.contains(user.id)) {
      return;
    }

    _followingUserIds.add(user.id);
    notifyListeners();

    try {
      if (user.isFollowedByMe) {
        final response = await _profileRepository.unfollowUser(user.id);
        _replaceUser(
          user.copyWith(
            isFollowedByMe: response['is_followed_by_me'] == true,
            hasRequestedFollow: response['has_requested_follow'] == true,
            followStatus:
                response['follow_status']?.toString() ?? 'not_following',
          ),
        );
      } else {
        final response = await _profileRepository.followUser(user.id);
        final followStatus =
            response['follow_status']?.toString() ??
            (user.isPrivate ? 'requested' : 'following');
        _replaceUser(
          user.copyWith(
            isFollowedByMe: response['is_followed_by_me'] == true,
            hasRequestedFollow:
                response['has_requested_follow'] == true ||
                followStatus == 'requested',
            followStatus: followStatus,
          ),
        );
      }
    } catch (_) {
      _errorMessage = 'Unable to update follow status.';
    } finally {
      _followingUserIds.remove(user.id);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _replaceUser(UserModel updated) {
    _recommendedUsers = _recommendedUsers
        .map((user) => user.id == updated.id ? updated : user)
        .toList();
    _exploreUsers = _exploreUsers
        .map((user) => user.id == updated.id ? updated : user)
        .toList();
  }
}
