import '../../auth/models/user_model.dart';
import '../../feed/models/post_model.dart';

class ActivityCommentModel {
  final int id;
  final String comment;
  final DateTime? createdAt;
  final PostModel? post;

  const ActivityCommentModel({
    required this.id,
    required this.comment,
    this.createdAt,
    this.post,
  });

  factory ActivityCommentModel.fromJson(Map<String, dynamic> json) {
    final postJson = json['post'];
    return ActivityCommentModel(
      id: _parseInt(json['id']),
      comment: json['comment']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
      post: postJson is Map<String, dynamic>
          ? PostModel.fromJson(postJson)
          : null,
    );
  }
}

class ActivityFollowModel {
  final int id;
  final DateTime? createdAt;
  final UserModel? user;

  const ActivityFollowModel({required this.id, this.createdAt, this.user});

  factory ActivityFollowModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return ActivityFollowModel(
      id: _parseInt(json['id']),
      createdAt: _parseDate(json['created_at']),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null,
    );
  }
}

class ActivityModel {
  final List<PostModel> posts;
  final List<ActivityCommentModel> comments;
  final List<PostModel> likes;
  final List<PostModel> saved;
  final List<ActivityFollowModel> follows;

  const ActivityModel({
    this.posts = const [],
    this.comments = const [],
    this.likes = const [],
    this.saved = const [],
    this.follows = const [],
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      posts: _parseList(json['posts']).map(PostModel.fromJson).toList(),
      comments: _parseList(
        json['comments'],
      ).map(ActivityCommentModel.fromJson).toList(),
      likes: _parseList(json['likes']).map(PostModel.fromJson).toList(),
      saved: _parseList(json['saved']).map(PostModel.fromJson).toList(),
      follows: _parseList(
        json['follows'],
      ).map(ActivityFollowModel.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _parseList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }
    return const [];
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
