import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../features/comments/models/comments_status_model.dart';
import '../../features/feed/models/feed_status_model.dart';

class RealtimeException implements Exception {
  final String message;

  const RealtimeException(this.message);

  @override
  String toString() => message;
}

class RealtimeRepository {
  final ApiClient _apiClient;

  RealtimeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<FeedStatusModel> getFeedStatus() async {
    final result = await _apiClient.get(ApiEndpoints.feedStatus);
    final data = _readData(result.data?.data, result.error);

    return FeedStatusModel.fromJson(data);
  }

  Future<CommentsStatusModel> getCommentsStatus(int postId) async {
    final result = await _apiClient.get(ApiEndpoints.commentsStatus(postId));
    final data = _readData(result.data?.data, result.error);

    return CommentsStatusModel.fromJson(data);
  }

  Map<String, dynamic> _readData(dynamic responseData, String? error) {
    if (error != null) {
      throw RealtimeException(error);
    }

    if (responseData is! Map<String, dynamic>) {
      throw const RealtimeException('Invalid realtime response from API.');
    }

    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const RealtimeException('Invalid realtime data from API.');
    }

    return data;
  }
}
