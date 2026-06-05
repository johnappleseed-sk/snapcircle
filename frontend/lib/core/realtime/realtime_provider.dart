import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/feed/models/feed_status_model.dart';
import '../../features/feed/providers/feed_provider.dart';
import '../constants/realtime_config.dart';
import 'realtime_repository.dart';

class RealtimeProvider extends ChangeNotifier {
  final RealtimeRepository _repository;

  FeedProvider? _feedProvider;
  Timer? _feedStatusTimer;
  FeedStatusModel? _feedStatus;
  bool _hasNewPosts = false;
  int _unreadNotificationsCount = 0;
  String? _errorMessage;
  bool _isPolling = false;

  RealtimeProvider({RealtimeRepository? repository})
    : _repository = repository ?? RealtimeRepository();

  FeedStatusModel? get feedStatus => _feedStatus;
  bool get hasNewPosts => _hasNewPosts;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  String? get errorMessage => _errorMessage;
  bool get isPolling => _isPolling;

  void updateFeedProvider(FeedProvider feedProvider) {
    _feedProvider = feedProvider;
  }

  void startFeedStatusPolling() {
    if (_feedStatusTimer != null) {
      return;
    }

    _isPolling = true;
    notifyListeners();
    unawaited(checkFeedStatus());
    _feedStatusTimer = Timer.periodic(
      RealtimeConfig.feedStatusPollInterval,
      (_) => unawaited(checkFeedStatus()),
    );
  }

  void stopFeedStatusPolling() {
    _feedStatusTimer?.cancel();
    _feedStatusTimer = null;
    if (_isPolling) {
      _isPolling = false;
      notifyListeners();
    }
  }

  Future<void> checkFeedStatus() async {
    try {
      final status = await _repository.getFeedStatus();
      _feedStatus = status;
      _unreadNotificationsCount = status.unreadNotificationsCount;
      _hasNewPosts = _feedProvider?.isNewerThanCurrentFeed(status) ?? false;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Live updates are temporarily unavailable.';
      notifyListeners();
    }
  }

  void markFeedAsSeen() {
    _hasNewPosts = false;
    notifyListeners();
  }

  void updateUnreadNotificationsCount(int count) {
    _unreadNotificationsCount = count < 0 ? 0 : count;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    final hadState =
        _feedStatus != null ||
        _hasNewPosts ||
        _unreadNotificationsCount != 0 ||
        _errorMessage != null ||
        _isPolling;

    stopFeedStatusPolling();
    _feedStatus = null;
    _hasNewPosts = false;
    _unreadNotificationsCount = 0;
    _errorMessage = null;
    if (hadState) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _feedStatusTimer?.cancel();
    super.dispose();
  }
}
