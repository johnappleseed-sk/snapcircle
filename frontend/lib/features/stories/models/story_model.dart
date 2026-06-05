import '../../auth/models/user_model.dart';

class StoryModel {
  final int id;
  final String? caption;
  final String? mediaUrl;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final bool isExpired;
  final int viewsCount;
  final bool viewedByMe;
  final bool isOwner;
  final bool canDelete;
  final UserModel user;

  const StoryModel({
    required this.id,
    required this.user,
    this.caption,
    this.mediaUrl,
    this.expiresAt,
    this.createdAt,
    this.isExpired = false,
    this.viewsCount = 0,
    this.viewedByMe = false,
    this.isOwner = false,
    this.canDelete = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return StoryModel(
      id: _parseInt(json['id']),
      caption: json['caption']?.toString(),
      mediaUrl: _parseMediaUrl(json),
      expiresAt: _parseDate(json['expires_at']),
      createdAt: _parseDate(json['created_at']),
      isExpired: _parseBool(json['is_expired']),
      viewsCount: _parseInt(json['views_count']),
      viewedByMe: _parseBool(json['viewed_by_me']),
      isOwner: _parseBool(json['is_owner']),
      canDelete: _parseBool(json['can_delete']),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : const UserModel(id: 0, name: 'Unknown User', email: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'media_url': mediaUrl,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'is_expired': isExpired,
      'views_count': viewsCount,
      'viewed_by_me': viewedByMe,
      'is_owner': isOwner,
      'can_delete': canDelete,
      'user': user.toJson(),
    };
  }

  StoryModel copyWith({
    int? id,
    String? caption,
    String? mediaUrl,
    DateTime? expiresAt,
    DateTime? createdAt,
    bool? isExpired,
    int? viewsCount,
    bool? viewedByMe,
    bool? isOwner,
    bool? canDelete,
    UserModel? user,
  }) {
    return StoryModel(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      isExpired: isExpired ?? this.isExpired,
      viewsCount: viewsCount ?? this.viewsCount,
      viewedByMe: viewedByMe ?? this.viewedByMe,
      isOwner: isOwner ?? this.isOwner,
      canDelete: canDelete ?? this.canDelete,
      user: user ?? this.user,
    );
  }

  static String? _parseMediaUrl(Map<String, dynamic> json) {
    final value = json['media_url'] ?? json['media_path'] ?? json['image_url'];
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime? _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
