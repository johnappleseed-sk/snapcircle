import 'post_model.dart';

class SavedCollectionModel {
  final int id;
  final String name;
  final int postsCount;
  final PostModel? latestPost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavedCollectionModel({
    required this.id,
    required this.name,
    this.postsCount = 0,
    this.latestPost,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedCollectionModel.fromJson(Map<String, dynamic> json) {
    final latestPostJson = json['latest_post'];
    return SavedCollectionModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? 'Saved collection',
      postsCount: _parseInt(json['posts_count']),
      latestPost: latestPostJson is Map<String, dynamic>
          ? PostModel.fromJson(latestPostJson)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  SavedCollectionModel copyWith({
    int? id,
    String? name,
    int? postsCount,
    PostModel? latestPost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      postsCount: postsCount ?? this.postsCount,
      latestPost: latestPost ?? this.latestPost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
