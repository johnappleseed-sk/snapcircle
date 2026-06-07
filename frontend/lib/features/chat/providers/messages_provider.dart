import 'package:flutter/foundation.dart';

import '../data/message_repository.dart';
import '../models/message_model.dart';

class MessagesProvider extends ChangeNotifier {
  final MessageRepository _repository;

  int? _conversationId;
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSending = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 30;
  String? _errorMessage;

  MessagesProvider({MessageRepository? repository})
    : _repository = repository ?? MessageRepository();

  int? get conversationId => _conversationId;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSending => _isSending;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMessages(int conversationId, {bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (_conversationId != conversationId || refresh) {
      _conversationId = conversationId;
      _currentPage = 1;
      _hasMore = true;
      if (refresh) {
        _messages = [];
      }
    }

    _isLoading = _messages.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getMessages(
        conversationId,
        page: _currentPage,
        perPage: _perPage,
      );
      _messages = response.items;
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
      await _markReceivedMessagesAsRead();
    } on MessageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load messages. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    final currentConversationId = _conversationId;
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        currentConversationId == null) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getMessages(
        currentConversationId,
        page: nextPage,
        perPage: _perPage,
      );
      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        _messages = _mergeMessages(_messages, response.items);
        _hasMore = response.hasMore;
        await _markReceivedMessagesAsRead();
      }
    } on MessageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load older messages.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<MessageModel?> sendMessage(String message) async {
    final currentConversationId = _conversationId;
    final trimmed = message.trim();
    if (trimmed.isEmpty || currentConversationId == null || _isSending) {
      return null;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sent = await _repository.sendMessage(
        currentConversationId,
        trimmed,
      );
      _messages = _mergeMessages([sent], _messages);
      return sent;
    } on MessageException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to send message. Please try again.';
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> markMessageAsRead(int messageId) async {
    try {
      final updated = await _repository.markAsRead(messageId);
      _messages = _messages
          .map((message) => message.id == messageId ? updated : message)
          .toList();
      notifyListeners();
    } catch (_) {
      // Read receipts are helpful but should not block chat usage.
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearConversation() {
    _conversationId = null;
    _messages = [];
    _isLoading = false;
    _isLoadingMore = false;
    _isSending = false;
    _hasMore = true;
    _currentPage = 1;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _markReceivedMessagesAsRead() async {
    final unreadReceived = _messages
        .where((message) => !message.isMine && !message.isRead)
        .toList();

    for (final message in unreadReceived) {
      await markMessageAsRead(message.id);
    }
  }

  List<MessageModel> _mergeMessages(
    List<MessageModel> current,
    List<MessageModel> next,
  ) {
    final seenIds = current.map((message) => message.id).toSet();
    return [...current, ...next.where((message) => seenIds.add(message.id))];
  }
}
