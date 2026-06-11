import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';
import '../../stories/models/story_model.dart';
import '../data/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  UserModel? _profile;
  UserModel? _selectedUser;
  List<PostModel> _profilePosts = [];
  List<StoryModel> _profileStories = [];
  List<UserModel> _blockedUsers = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isFollowing = false;
  bool _isBlocking = false;
  bool _isLoadingBlockedUsers = false;
  bool _isLoadingPosts = false;
  bool _isLoadingMorePosts = false;
  bool _isLoadingStories = false;
  bool _hasMorePosts = true;
  int _currentPostsPage = 1;
  int _currentStoriesPage = 1;
  String _currentPostsSort = 'latest';
  String? _errorMessage;
  String? _storiesErrorMessage;

  ProfileProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository();

  UserModel? get profile => _profile;
  UserModel? get selectedUser => _selectedUser;
  List<PostModel> get profilePosts => List.unmodifiable(_profilePosts);
  List<StoryModel> get profileStories => List.unmodifiable(_profileStories);
  List<UserModel> get blockedUsers => List.unmodifiable(_blockedUsers);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isFollowing => _isFollowing;
  bool get isBlocking => _isBlocking;
  bool get isLoadingBlockedUsers => _isLoadingBlockedUsers;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingMorePosts => _isLoadingMorePosts;
  bool get isLoadingStories => _isLoadingStories;
  bool get hasMorePosts => _hasMorePosts;
  int get currentPostsPage => _currentPostsPage;
  String get currentPostsSort => _currentPostsSort;
  String? get errorMessage => _errorMessage;
  String? get storiesErrorMessage => _storiesErrorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.getProfile();
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> updateProfile({
    required String name,
    String? username,
    String? bio,
    String? location,
    String? website,
    XFile? avatar,
    XFile? coverImage,
    bool isPrivate = false,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileRepository.updateProfile(
        name: name,
        username: username,
        bio: bio,
        location: location,
        website: website,
        avatar: avatar,
        coverImage: coverImage,
        isPrivate: isPrivate,
      );
      _profile = updatedProfile;
      return updatedProfile;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to update profile. Please try again.';
      return null;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserById(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await _profileRepository.getUserById(userId);
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load user profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserByUsername(String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await _profileRepository.getUserByUsername(username);
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load user profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfilePosts(int userId, {bool refresh = false}) async {
    if (_isLoadingPosts || _isLoadingMorePosts) {
      return;
    }

    if (refresh) {
      _currentPostsPage = 1;
      _hasMorePosts = true;
    }

    _isLoadingPosts = refresh || _profilePosts.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getUserPosts(
        userId,
        page: _currentPostsPage,
        sort: _currentPostsSort,
      );
      _profilePosts = response.items;
      _currentPostsPage = response.currentPage;
      _hasMorePosts = response.hasMore;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load profile posts. Please try again.';
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProfilePosts(int userId) async {
    if (_isLoadingPosts || _isLoadingMorePosts || !_hasMorePosts) {
      return;
    }

    _isLoadingMorePosts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPostsPage + 1;
      final response = await _profileRepository.getUserPosts(
        userId,
        page: nextPage,
        sort: _currentPostsSort,
      );

      if (response.items.isEmpty) {
        _hasMorePosts = false;
      } else {
        _currentPostsPage = response.currentPage;
        _profilePosts = _mergePosts(_profilePosts, response.items);
        _hasMorePosts = response.hasMore;
      }
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more profile posts. Please try again.';
    } finally {
      _isLoadingMorePosts = false;
      notifyListeners();
    }
  }

  Future<void> changePostsSort(String sort) async {
    if (sort == _currentPostsSort) {
      return;
    }

    _currentPostsSort = sort;
    final userId = _selectedUser?.id ?? _profile?.id;
    if (userId != null) {
      await fetchProfilePosts(userId, refresh: true);
    }
  }

  Future<void> fetchProfileStories(int userId, {bool refresh = false}) async {
    if (_isLoadingStories) {
      return;
    }

    if (refresh) {
      _currentStoriesPage = 1;
    }

    _isLoadingStories = true;
    _storiesErrorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getUserStories(
        userId,
        page: _currentStoriesPage,
      );
      _profileStories = response.items;
      _currentStoriesPage = response.currentPage;
    } on ProfileException catch (error) {
      _storiesErrorMessage = error.message;
    } catch (_) {
      _storiesErrorMessage = 'Unable to load profile stories.';
    } finally {
      _isLoadingStories = false;
      notifyListeners();
    }
  }

  Future<bool> followUser(int userId) async {
    return _setFollowStatus(userId, shouldFollow: true);
  }

  Future<bool> unfollowUser(int userId) async {
    return _setFollowStatus(userId, shouldFollow: false);
  }

  Future<void> fetchBlockedUsers() async {
    _isLoadingBlockedUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getBlockedUsers();
      _blockedUsers = response.items;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load blocked users. Please try again.';
    } finally {
      _isLoadingBlockedUsers = false;
      notifyListeners();
    }
  }

  Future<bool> blockUser(int userId) async {
    return _setBlockStatus(userId, shouldBlock: true);
  }

  Future<bool> unblockUser(int userId) async {
    return _setBlockStatus(userId, shouldBlock: false);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _setFollowStatus(
    int userId, {
    required bool shouldFollow,
  }) async {
    if (_isFollowing) {
      return false;
    }

    _isFollowing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = shouldFollow
          ? await _profileRepository.followUser(userId)
          : await _profileRepository.unfollowUser(userId);

      final user = _selectedUser;
      if (user != null && user.id == userId) {
        _selectedUser = user.copyWith(
          isFollowedByMe: response['is_followed_by_me'] is bool
              ? response['is_followed_by_me'] as bool
              : shouldFollow,
          followersCount: response['followers_count'] is int
              ? response['followers_count'] as int
              : _optimisticFollowersCount(user, shouldFollow),
        );
      }

      return true;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = shouldFollow
          ? 'Unable to follow this user. Please try again.'
          : 'Unable to unfollow this user. Please try again.';
      return false;
    } finally {
      _isFollowing = false;
      notifyListeners();
    }
  }

  Future<bool> _setBlockStatus(int userId, {required bool shouldBlock}) async {
    if (_isBlocking) {
      return false;
    }

    _isBlocking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = shouldBlock
          ? await _profileRepository.blockUser(userId)
          : await _profileRepository.unblockUser(userId);

      if (_selectedUser?.id == userId) {
        _selectedUser = updatedUser;
      }

      if (shouldBlock) {
        _profilePosts = [];
        _profileStories = [];
        _blockedUsers = [
          updatedUser,
          ..._blockedUsers.where((user) => user.id != updatedUser.id),
        ];
      } else {
        _blockedUsers = _blockedUsers
            .where((user) => user.id != updatedUser.id)
            .toList();
      }

      return true;
    } on ProfileException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = shouldBlock
          ? 'Unable to block this user. Please try again.'
          : 'Unable to unblock this user. Please try again.';
      return false;
    } finally {
      _isBlocking = false;
      notifyListeners();
    }
  }

  int _optimisticFollowersCount(UserModel user, bool shouldFollow) {
    if (shouldFollow && !user.isFollowedByMe) {
      return user.followersCount + 1;
    }

    if (!shouldFollow && user.isFollowedByMe) {
      return user.followersCount > 0 ? user.followersCount - 1 : 0;
    }

    return user.followersCount;
  }

  List<PostModel> _mergePosts(List<PostModel> current, List<PostModel> next) {
    final seenIds = current.map((post) => post.id).toSet();
    return [...current, ...next.where((post) => seenIds.add(post.id))];
  }
}
