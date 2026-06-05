import '../../auth/models/user_model.dart';

class PostModel {
  final int id;
  final String? content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool isOwner;
  final bool canDelete;
  final bool canUpdate;
  final DateTime? createdAt;
  final UserModel user;

  const PostModel({
    required this.id,
    required this.user,
    this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.isOwner = false,
    this.canDelete = false,
    this.canUpdate = false,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return PostModel(
      id: _parseInt(json['id']),
      content: json['content']?.toString(),
      imageUrl: _parseImageUrl(json),
      likesCount: _parseInt(json['likes_count']),
      commentsCount: _parseInt(json['comments_count']),
      likedByMe: _parseBool(json['liked_by_me']),
      isOwner: _parseBool(json['is_owner']),
      canDelete: _parseBool(json['can_delete']),
      canUpdate: _parseBool(json['can_update']),
      createdAt: _parseDate(json['created_at']),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : const UserModel(id: 0, name: 'Unknown User', email: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'liked_by_me': likedByMe,
      'is_owner': isOwner,
      'can_delete': canDelete,
      'can_update': canUpdate,
      'created_at': createdAt?.toIso8601String(),
      'user': user.toJson(),
    };
  }

  PostModel copyWith({
    int? id,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
    bool? isOwner,
    bool? canDelete,
    bool? canUpdate,
    DateTime? createdAt,
    UserModel? user,
  }) {
    return PostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isOwner: isOwner ?? this.isOwner,
      canDelete: canDelete ?? this.canDelete,
      canUpdate: canUpdate ?? this.canUpdate,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  static String? _parseImageUrl(Map<String, dynamic> json) {
    final image = json['image_url'] ?? json['image_path'] ?? json['image'];
    final imageUrl = image?.toString();
    return imageUrl == null || imageUrl.isEmpty ? null : imageUrl;
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
