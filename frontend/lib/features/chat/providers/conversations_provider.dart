import 'package:flutter/foundation.dart';

import '../data/conversation_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ConversationsProvider extends ChangeNotifier {
  final ConversationRepository _repository;

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 15;
  final Set<int> _startingUserIds = {};
  String? _errorMessage;

  ConversationsProvider({ConversationRepository? repository})
    : _repository = repository ?? ConversationRepository();

  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  bool isStartingConversation(int userId) => _startingUserIds.contains(userId);

  Future<void> fetchConversations({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _conversations.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getConversations(
        page: _currentPage,
        perPage: _perPage,
      );
      _conversations = response.items;
      _currentPage = response.currentPage;
      _hasMore = response.hasMore;
    } on ConversationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load conversations. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreConversations() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getConversations(
        page: nextPage,
        perPage: _perPage,
      );
      if (response.items.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = response.currentPage;
        _conversations = _mergeConversations(_conversations, response.items);
        _hasMore = response.hasMore;
      }
    } on ConversationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load more conversations.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> startConversation(int userId) async {
    if (_startingUserIds.contains(userId)) {
      return null;
    }

    _startingUserIds.add(userId);
    _errorMessage = null;
    notifyListeners();

    try {
      final conversation = await _repository.startConversation(userId);
      _upsertConversation(conversation);
      return conversation;
    } on ConversationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to start conversation. Please try again.';
      return null;
    } finally {
      _startingUserIds.remove(userId);
      notifyListeners();
    }
  }

  void updateLatestMessage(int conversationId, MessageModel message) {
    _conversations = _conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }

      return conversation.copyWith(
        latestMessage: message,
        updatedAt: message.createdAt ?? DateTime.now(),
        unreadCount: 0,
      );
    }).toList();
    _sortConversations();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _upsertConversation(ConversationModel conversation) {
    final exists = _conversations.any((item) => item.id == conversation.id);
    _conversations = exists
        ? _conversations
              .map((item) => item.id == conversation.id ? conversation : item)
              .toList()
        : [conversation, ..._conversations];
    _sortConversations();
  }

  List<ConversationModel> _mergeConversations(
    List<ConversationModel> current,
    List<ConversationModel> next,
  ) {
    final seenIds = current.map((conversation) => conversation.id).toSet();
    return [
      ...current,
      ...next.where((conversation) => seenIds.add(conversation.id)),
    ];
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final aDate =
          a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }
}
