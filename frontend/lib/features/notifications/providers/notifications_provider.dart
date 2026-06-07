import 'package:flutter/foundation.dart';

import '../data/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 15;
  int _unreadCount = 0;
  String _currentFilter = 'all';
  String? _errorMessage;

  NotificationsProvider({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository();

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get unreadCount => _unreadCount;
  String get currentFilter => _currentFilter;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore || _isRefreshing) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _notifications.isEmpty;
    _isRefreshing = refresh && _notifications.isNotEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        page: _currentPage,
        perPage: _perPage,
        filter: _currentFilter,
      );
      _notifications = response.items;
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
    } on NotificationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load notifications. Please try again.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getNotifications(
        page: nextPage,
        perPage: _perPage,
        filter: _currentFilter,
      );
      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        _notifications = _mergeNotifications(_notifications, response.items);
        _hasMore = response.hasMore;
      }
    } on NotificationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more notifications. Please try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    await fetchUnreadCount();
    await fetchNotifications(refresh: true);
  }

  Future<void> changeFilter(String filter) async {
    if (_currentFilter == filter) {
      return;
    }
    _currentFilter = filter;
    await fetchNotifications(refresh: true);
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Badge failures should not block the rest of the UI.
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final current = _findNotification(notificationId);
    if (current == null || current.isRead) {
      return;
    }

    try {
      final updated = await _repository.markAsRead(notificationId);
      _replaceNotification(updated);
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications = _notifications
          .map(
            (notification) => notification.copyWith(
              isRead: true,
              readAt: notification.readAt ?? DateTime.now(),
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    final current = _findNotification(notificationId);
    try {
      await _repository.deleteNotification(notificationId);
      _notifications = _notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      if (current != null && !current.isRead) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      notifyListeners();
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  NotificationModel? _findNotification(int id) {
    for (final notification in _notifications) {
      if (notification.id == id) {
        return notification;
      }
    }
    return null;
  }

  void _replaceNotification(NotificationModel updated) {
    _notifications = _notifications
        .map(
          (notification) =>
              notification.id == updated.id ? updated : notification,
        )
        .toList();
  }

  List<NotificationModel> _mergeNotifications(
    List<NotificationModel> current,
    List<NotificationModel> next,
  ) {
    final seenIds = current.map((notification) => notification.id).toSet();
    return [
      ...current,
      ...next.where((notification) => seenIds.add(notification.id)),
    ];
  }
}
