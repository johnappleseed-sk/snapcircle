import '../../auth/models/user_model.dart';

class CommentModel {
  final int id;
  final String comment;
  final DateTime? createdAt;
  final UserModel user;

  const CommentModel({
    required this.id,
    required this.comment,
    required this.user,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return CommentModel(
      id: _parseInt(json['id']),
      comment: (json['comment'] ?? json['text'] ?? json['body'] ?? '')
          .toString(),
      createdAt: _parseDate(json['created_at']),
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
      'user': user.toJson(),
    };
  }

  CommentModel copyWith({
    int? id,
    String? comment,
    DateTime? createdAt,
    UserModel? user,
  }) {
    return CommentModel(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
