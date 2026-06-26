import '../../auth/models/user_model.dart';

class PostMediaModel {
  final int? id;
  final String url;
  final String type;
  final int sortOrder;

  const PostMediaModel({
    required this.url,
    this.id,
    this.type = 'image',
    this.sortOrder = 0,
  });

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    return PostMediaModel(
      id: json['id'] == null ? null : PostModel._parseInt(json['id']),
      url: (json['url'] ?? json['image_url'] ?? json['path'] ?? '').toString(),
      type: (json['type'] ?? 'image').toString(),
      sortOrder: PostModel._parseInt(json['sort_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'type': type, 'sort_order': sortOrder};
  }
}

class PostModel {
  final int id;
  final String? content;
  final String? imageUrl;
  final List<PostMediaModel> media;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final bool likedByMe;
  final bool savedByMe;
  final bool isOwner;
  final bool canDelete;
  final bool canUpdate;
  final int reportsCount;
  final int pendingReportsCount;
  final DateTime? createdAt;
  final UserModel user;

  const PostModel({
    required this.id,
    required this.user,
    this.content,
    this.imageUrl,
    this.media = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.savesCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.isOwner = false,
    this.canDelete = false,
    this.canUpdate = false,
    this.reportsCount = 0,
    this.pendingReportsCount = 0,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    final media = _parseMedia(json);
    final imageUrl = media.isNotEmpty ? media.first.url : _parseImageUrl(json);

    return PostModel(
      id: _parseInt(json['id']),
      content: json['content']?.toString(),
      imageUrl: imageUrl,
      media: media,
      likesCount: _parseInt(json['likes_count']),
      commentsCount: _parseInt(json['comments_count']),
      savesCount: _parseInt(json['saves_count']),
      likedByMe: _parseBool(json['liked_by_me']),
      savedByMe: _parseBool(json['saved_by_me']),
      isOwner: _parseBool(json['is_owner']),
      canDelete: _parseBool(json['can_delete']),
      canUpdate: _parseBool(json['can_update']),
      reportsCount: _parseInt(json['reports_count']),
      pendingReportsCount: _parseInt(json['pending_reports_count']),
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
      'media': media.map((item) => item.toJson()).toList(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'saves_count': savesCount,
      'liked_by_me': likedByMe,
      'saved_by_me': savedByMe,
      'is_owner': isOwner,
      'can_delete': canDelete,
      'can_update': canUpdate,
      'reports_count': reportsCount,
      'pending_reports_count': pendingReportsCount,
      'created_at': createdAt?.toIso8601String(),
      'user': user.toJson(),
    };
  }

  PostModel copyWith({
    int? id,
    String? content,
    String? imageUrl,
    List<PostMediaModel>? media,
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    bool? likedByMe,
    bool? savedByMe,
    bool? isOwner,
    bool? canDelete,
    bool? canUpdate,
    int? reportsCount,
    int? pendingReportsCount,
    DateTime? createdAt,
    UserModel? user,
  }) {
    return PostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      media: media ?? this.media,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      savesCount: savesCount ?? this.savesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      isOwner: isOwner ?? this.isOwner,
      canDelete: canDelete ?? this.canDelete,
      canUpdate: canUpdate ?? this.canUpdate,
      reportsCount: reportsCount ?? this.reportsCount,
      pendingReportsCount: pendingReportsCount ?? this.pendingReportsCount,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  static String? _parseImageUrl(Map<String, dynamic> json) {
    final image = json['image_url'] ?? json['image_path'] ?? json['image'];
    final imageUrl = image?.toString();
    return imageUrl == null || imageUrl.isEmpty ? null : imageUrl;
  }

  static List<PostMediaModel> _parseMedia(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    if (rawMedia is! List) {
      final imageUrl = _parseImageUrl(json);
      return imageUrl == null
          ? const []
          : [PostMediaModel(url: imageUrl, sortOrder: 0)];
    }

    final media =
        rawMedia
            .whereType<Map>()
            .map(
              (item) =>
                  PostMediaModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.url.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (media.isNotEmpty) {
      return media;
    }

    final imageUrl = _parseImageUrl(json);
    return imageUrl == null
        ? const []
        : [PostMediaModel(url: imageUrl, sortOrder: 0)];
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
