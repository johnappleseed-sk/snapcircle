class FeedStatusModel {
  final int? latestPostId;
  final DateTime? latestPostCreatedAt;
  final int totalPostsCount;
  final int unreadNotificationsCount;

  const FeedStatusModel({
    required this.latestPostId,
    required this.latestPostCreatedAt,
    required this.totalPostsCount,
    required this.unreadNotificationsCount,
  });

  factory FeedStatusModel.fromJson(Map<String, dynamic> json) {
    return FeedStatusModel(
      latestPostId: json['latest_post_id'] is int
          ? json['latest_post_id'] as int
          : int.tryParse(json['latest_post_id']?.toString() ?? ''),
      latestPostCreatedAt: DateTime.tryParse(
        json['latest_post_created_at']?.toString() ?? '',
      ),
      totalPostsCount: json['total_posts_count'] is int
          ? json['total_posts_count'] as int
          : int.tryParse(json['total_posts_count']?.toString() ?? '') ?? 0,
      unreadNotificationsCount: json['unread_notifications_count'] is int
          ? json['unread_notifications_count'] as int
          : int.tryParse(
                  json['unread_notifications_count']?.toString() ?? '',
                ) ??
                0,
    );
  }

  FeedStatusModel copyWith({
    int? latestPostId,
    DateTime? latestPostCreatedAt,
    int? totalPostsCount,
    int? unreadNotificationsCount,
  }) {
    return FeedStatusModel(
      latestPostId: latestPostId ?? this.latestPostId,
      latestPostCreatedAt: latestPostCreatedAt ?? this.latestPostCreatedAt,
      totalPostsCount: totalPostsCount ?? this.totalPostsCount,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }
}
