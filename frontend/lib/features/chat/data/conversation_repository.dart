import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/conversation_model.dart';

class ConversationException implements Exception {
  final String message;

  const ConversationException(this.message);

  @override
  String toString() => message;
}

class ConversationRepository {
  final ApiClient _apiClient;

  ConversationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.conversations,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final response = _readResponse(result.data?.data, result.error);
    final items = _extractList(response, 'conversations');

    return items.map(ConversationModel.fromJson).toList();
  }

  Future<ConversationModel> startConversation(int userId) async {
    final result = await _apiClient.post(
      ApiEndpoints.conversations,
      data: {'user_id': userId},
    );

    return _parseConversation(result.data?.data, result.error);
  }

  Future<ConversationModel> getConversation(int conversationId) async {
    final result = await _apiClient.get(
      ApiEndpoints.conversationById(conversationId),
    );

    return _parseConversation(result.data?.data, result.error);
  }

  ConversationModel _parseConversation(dynamic responseData, String? error) {
    final response = _readResponse(responseData, error);
    final data = response['data'];
    final conversationJson = data is Map<String, dynamic>
        ? data['conversation']
        : response['conversation'];

    if (conversationJson is! Map<String, dynamic>) {
      throw const ConversationException('Invalid conversation response.');
    }

    return ConversationModel.fromJson(conversationJson);
  }

  Map<String, dynamic> _readResponse(dynamic responseData, String? error) {
    if (error != null) {
      throw ConversationException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const ConversationException('Invalid response from API.');
    }

    return responseData;
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
    String key,
  ) {
    final data = response['data'];
    final list = data is List
        ? data
        : response[key] is List
        ? response[key]
        : data is Map<String, dynamic> && data[key] is List
        ? data[key]
        : data is Map<String, dynamic> && data['data'] is List
        ? data['data']
        : null;

    if (list is! List) {
      throw const ConversationException('Invalid conversation list response.');
    }

    return list.whereType<Map<String, dynamic>>().toList();
  }
}
