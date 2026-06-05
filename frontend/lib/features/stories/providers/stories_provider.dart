import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/story_repository.dart';
import '../models/story_model.dart';

class StoriesProvider extends ChangeNotifier {
  final StoryRepository _repository;

  List<StoryModel> _stories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 15;
  String _currentMode = 'all';
  String? _errorMessage;

  StoriesProvider({StoryRepository? repository})
    : _repository = repository ?? StoryRepository();

  List<StoryModel> get stories => List.unmodifiable(_stories);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreating => _isCreating;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String get currentMode => _currentMode;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStories({bool refresh = false, String? mode}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (mode != null) {
      _currentMode = mode;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _stories.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.getStories(
        page: _currentPage,
        perPage: _perPage,
        mode: _currentMode,
      );
      _stories = items;
      _hasMore = items.length >= _perPage;
    } on StoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load stories. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreStories() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final items = await _repository.getStories(
        page: nextPage,
        perPage: _perPage,
        mode: _currentMode,
      );
      if (items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        _stories = [..._stories, ...items];
        _hasMore = items.length >= _perPage;
      }
    } on StoryException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more stories.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createStory({required File media, String? caption}) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final story = await _repository.createStory(
        media: media,
        caption: caption,
      );
      _stories = [story, ..._stories];
      return true;
    } on StoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create story. Please try again.';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStory(int storyId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteStory(storyId);
      _stories = _stories.where((story) => story.id != storyId).toList();
      return true;
    } on StoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to delete story. Please try again.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markStoryAsViewed(int storyId) async {
    try {
      final data = await _repository.markStoryAsViewed(storyId);
      final viewsCount = _parseInt(data['views_count']);
      _stories = _stories.map((story) {
        if (story.id != storyId) {
          return story;
        }

        return story.copyWith(viewedByMe: true, viewsCount: viewsCount);
      }).toList();
      notifyListeners();
    } catch (_) {
      // Viewing should not block the story viewer.
    }
  }

  Future<void> changeMode(String mode) {
    if (_currentMode == mode) {
      return Future.value();
    }

    return fetchStories(refresh: true, mode: mode);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
