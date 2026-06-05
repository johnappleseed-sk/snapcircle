import '../../auth/models/user_model.dart';

class MessageModel {
  final int id;
  final int conversationId;
  final String message;
  final UserModel sender;
  final bool isMine;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.sender,
    required this.isMine,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : <String, dynamic>{'id': json['sender_id'] ?? 0, 'name': 'Unknown'};

    return MessageModel(
      id: _parseInt(json['id']),
      conversationId: _parseInt(json['conversation_id']),
      message: json['message']?.toString() ?? '',
      sender: UserModel.fromJson(senderJson),
      isMine: _parseBool(json['is_mine']),
      isRead: _parseBool(json['is_read']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'message': message,
      'sender': sender.toJson(),
      'is_mine': isMine,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    String? message,
    UserModel? sender,
    bool? isMine,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
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
