class CommentsStatusModel {
  final int postId;
  final int? latestCommentId;
  final DateTime? latestCommentCreatedAt;
  final int commentsCount;

  const CommentsStatusModel({
    required this.postId,
    required this.latestCommentId,
    required this.latestCommentCreatedAt,
    required this.commentsCount,
  });

  factory CommentsStatusModel.fromJson(Map<String, dynamic> json) {
    return CommentsStatusModel(
      postId: json['post_id'] is int
          ? json['post_id'] as int
          : int.tryParse(json['post_id']?.toString() ?? '') ?? 0,
      latestCommentId: json['latest_comment_id'] is int
          ? json['latest_comment_id'] as int
          : int.tryParse(json['latest_comment_id']?.toString() ?? ''),
      latestCommentCreatedAt: DateTime.tryParse(
        json['latest_comment_created_at']?.toString() ?? '',
      ),
      commentsCount: json['comments_count'] is int
          ? json['comments_count'] as int
          : int.tryParse(json['comments_count']?.toString() ?? '') ?? 0,
    );
  }

  CommentsStatusModel copyWith({
    int? postId,
    int? latestCommentId,
    DateTime? latestCommentCreatedAt,
    int? commentsCount,
  }) {
    return CommentsStatusModel(
      postId: postId ?? this.postId,
      latestCommentId: latestCommentId ?? this.latestCommentId,
      latestCommentCreatedAt:
          latestCommentCreatedAt ?? this.latestCommentCreatedAt,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
