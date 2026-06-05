import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/message_model.dart';

class MessageException implements Exception {
  final String message;

  const MessageException(this.message);

  @override
  String toString() => message;
}

class MessageRepository {
  final ApiClient _apiClient;

  MessageRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<MessageModel>> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = 30,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.conversationMessages(conversationId),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final response = _readResponse(result.data?.data, result.error);
    final items = _extractList(response);

    return items.map(MessageModel.fromJson).toList();
  }

  Future<MessageModel> sendMessage(int conversationId, String message) async {
    final result = await _apiClient.post(
      ApiEndpoints.conversationMessages(conversationId),
      data: {'message': message.trim()},
    );

    return _parseMessage(result.data?.data, result.error);
  }

  Future<MessageModel> markAsRead(int messageId) async {
    final result = await _apiClient.put(
      ApiEndpoints.markMessageRead(messageId),
    );

    return _parseMessage(result.data?.data, result.error);
  }

  MessageModel _parseMessage(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final data = response['data'];
    final messageJson = data is Map<String, dynamic>
        ? data['message']
        : response['message'];

    if (messageJson is! Map<String, dynamic>) {
      throw const MessageException('Invalid message response.');
    }

    return MessageModel.fromJson(messageJson);
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw MessageException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const MessageException('Invalid response from API.');
    }

    return responseData;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    final list = data is List
        ? data
        : response['messages'] is List
        ? response['messages']
        : data is Map<String, dynamic> && data['messages'] is List
        ? data['messages']
        : data is Map<String, dynamic> && data['data'] is List
        ? data['data']
        : null;

    if (list is! List) {
      throw const MessageException('Invalid message list response.');
    }

    return list.whereType<Map<String, dynamic>>().toList();
  }
}
