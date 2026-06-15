class TrendingTagModel {
  final String tag;
  final String label;
  final int postsCount;
  final DateTime? latestPostedAt;

  const TrendingTagModel({
    required this.tag,
    required this.label,
    required this.postsCount,
    this.latestPostedAt,
  });

  factory TrendingTagModel.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag'] ?? '').toString();
    final label = (json['label'] ?? '#$tag').toString();

    return TrendingTagModel(
      tag: tag,
      label: label,
      postsCount: _parseInt(json['posts_count']),
      latestPostedAt: DateTime.tryParse(
        (json['latest_posted_at'] ?? '').toString(),
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
