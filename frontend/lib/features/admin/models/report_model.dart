import '../../auth/models/user_model.dart';

class ReportModel {
  final int id;
  final String type;
  final String reason;
  final String status;
  final String? description;
  final String? actionTaken;
  final UserModel? reporter;
  final UserModel? reviewer;
  final String preview;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const ReportModel({
    required this.id,
    required this.type,
    required this.reason,
    required this.status,
    this.description,
    this.actionTaken,
    this.reporter,
    this.reviewer,
    this.preview = '',
    this.createdAt,
    this.reviewedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final reporterJson = json['reporter'];
    final reviewerJson = json['reviewer'];
    return ReportModel(
      id: _int(json['id']),
      type: json['type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      description: json['description']?.toString(),
      actionTaken: json['action_taken']?.toString(),
      reporter: reporterJson is Map<String, dynamic>
          ? UserModel.fromJson(reporterJson)
          : null,
      reviewer: reviewerJson is Map<String, dynamic>
          ? UserModel.fromJson(reviewerJson)
          : null,
      preview: _preview(json['reportable_preview']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
    );
  }

  static String _preview(dynamic value) {
    if (value is! Map<String, dynamic>) return 'Content unavailable';
    return (value['content_preview'] ??
            value['comment_preview'] ??
            value['message_preview'] ??
            value['name'] ??
            'Content preview')
        .toString();
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
