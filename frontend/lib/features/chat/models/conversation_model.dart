import '../../auth/models/user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final int id;
  final List<UserModel> participants;
  final MessageModel? latestMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.latestMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] is List
        ? json['participants'] as List
        : json['users'] is List
        ? json['users'] as List
        : const [];
    final latestMessageJson = json['latest_message'];

    return ConversationModel(
      id: _parseInt(json['id']),
      participants: participantsJson
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList(),
      latestMessage: latestMessageJson is Map<String, dynamic>
          ? MessageModel.fromJson(latestMessageJson)
          : null,
      unreadCount: _parseInt(json['unread_count']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((user) => user.toJson()).toList(),
      'latest_message': latestMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    int? id,
    List<UserModel>? participants,
    MessageModel? latestMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      latestMessage: latestMessage ?? this.latestMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserModel? otherParticipant(int? currentUserId) {
    for (final participant in participants) {
      if (participant.id != currentUserId) {
        return participant;
      }
    }

    return participants.isEmpty ? null : participants.first;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
