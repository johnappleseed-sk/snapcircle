import '../../auth/models/user_model.dart';

class NotificationModel {
  final int id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final UserModel? actor;
  final int? postId;
  final int? commentId;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.actor,
    this.postId,
    this.commentId,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actorJson = json['actor'];
    final postJson = json['post'];
    final commentJson = json['comment'];
    final dataJson = json['data'];

    return NotificationModel(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? 'You have a new notification.',
      isRead: _parseBool(json['is_read']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
      actor: actorJson is Map<String, dynamic>
          ? UserModel.fromJson(actorJson)
          : null,
      postId: postJson is Map<String, dynamic>
          ? _parseNullableInt(postJson['id'])
          : _parseNullableInt(json['post_id']),
      commentId: commentJson is Map<String, dynamic>
          ? _parseNullableInt(commentJson['id'])
          : _parseNullableInt(json['comment_id']),
      data: dataJson is Map<String, dynamic> ? dataJson : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'actor': actor?.toJson(),
      'post_id': postId,
      'comment_id': commentId,
      'data': data,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? message,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    UserModel? actor,
    int? postId,
    int? commentId,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      actor: actor ?? this.actor,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      data: data ?? this.data,
    );
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

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value == 1;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
