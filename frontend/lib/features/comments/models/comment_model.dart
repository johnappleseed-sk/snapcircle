import '../../auth/models/user_model.dart';

class CommentModel {
  final int id;
  final String comment;
  final DateTime? createdAt;
  final UserModel user;
  final int reportsCount;
  final int? postId;

  const CommentModel({
    required this.id,
    required this.comment,
    required this.user,
    this.createdAt,
    this.reportsCount = 0,
    this.postId,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return CommentModel(
      id: _parseInt(json['id']),
      comment: (json['comment'] ?? json['text'] ?? json['body'] ?? '')
          .toString(),
      createdAt: _parseDate(json['created_at']),
      reportsCount: _parseInt(json['reports_count']),
      postId: _parseNullableInt(json['post_id'] ?? _postId(json['post'])),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : const UserModel(id: 0, name: 'Unknown User', email: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
      'reports_count': reportsCount,
      'post_id': postId,
      'user': user.toJson(),
    };
  }

  CommentModel copyWith({
    int? id,
    String? comment,
    DateTime? createdAt,
    UserModel? user,
    int? reportsCount,
    int? postId,
  }) {
    return CommentModel(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      reportsCount: reportsCount ?? this.reportsCount,
      postId: postId ?? this.postId,
    );
  }

  static dynamic _postId(dynamic postJson) {
    if (postJson is Map<String, dynamic>) {
      return postJson['id'];
    }

    return null;
  }

  static int _parseInt(dynamic value) {
    return _parseNullableInt(value) ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
