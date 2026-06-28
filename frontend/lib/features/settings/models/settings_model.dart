class SettingsModel {
  final bool allowMessages;
  final bool showEmail;
  final bool pushNotificationsEnabled;
  final bool notifyLikes;
  final bool notifyComments;
  final bool notifyFollows;
  final bool notifyFollowRequests;
  final bool notifyMessages;
  final bool notifyMentions;
  final bool emailNotificationsEnabled;
  final bool marketingEmailsEnabled;
  final bool isPrivate;
  final String accountStatus;

  const SettingsModel({
    this.allowMessages = true,
    this.showEmail = false,
    this.pushNotificationsEnabled = true,
    this.notifyLikes = true,
    this.notifyComments = true,
    this.notifyFollows = true,
    this.notifyFollowRequests = true,
    this.notifyMessages = true,
    this.notifyMentions = true,
    this.emailNotificationsEnabled = false,
    this.marketingEmailsEnabled = false,
    this.isPrivate = false,
    this.accountStatus = 'active',
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      allowMessages: _parseBool(json['allow_messages'], fallback: true),
      showEmail: _parseBool(json['show_email']),
      pushNotificationsEnabled: _parseBool(
        json['push_notifications_enabled'],
        fallback: true,
      ),
      notifyLikes: _parseBool(json['notify_likes'], fallback: true),
      notifyComments: _parseBool(json['notify_comments'], fallback: true),
      notifyFollows: _parseBool(json['notify_follows'], fallback: true),
      notifyFollowRequests: _parseBool(
        json['notify_follow_requests'],
        fallback: true,
      ),
      notifyMessages: _parseBool(json['notify_messages'], fallback: true),
      notifyMentions: _parseBool(json['notify_mentions'], fallback: true),
      emailNotificationsEnabled: _parseBool(
        json['email_notifications_enabled'],
      ),
      marketingEmailsEnabled: _parseBool(json['marketing_emails_enabled']),
      isPrivate: _parseBool(json['is_private']),
      accountStatus: json['account_status']?.toString().isNotEmpty == true
          ? json['account_status'].toString()
          : 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_messages': allowMessages,
      'show_email': showEmail,
      'push_notifications_enabled': pushNotificationsEnabled,
      'notify_likes': notifyLikes,
      'notify_comments': notifyComments,
      'notify_follows': notifyFollows,
      'notify_follow_requests': notifyFollowRequests,
      'notify_messages': notifyMessages,
      'notify_mentions': notifyMentions,
      'email_notifications_enabled': emailNotificationsEnabled,
      'marketing_emails_enabled': marketingEmailsEnabled,
      'is_private': isPrivate,
      'account_status': accountStatus,
    };
  }

  Map<String, dynamic> toSettingsUpdateJson() {
    return {
      'allow_messages': allowMessages,
      'show_email': showEmail,
      'push_notifications_enabled': pushNotificationsEnabled,
      'notify_likes': notifyLikes,
      'notify_comments': notifyComments,
      'notify_follows': notifyFollows,
      'notify_follow_requests': notifyFollowRequests,
      'notify_messages': notifyMessages,
      'notify_mentions': notifyMentions,
      'email_notifications_enabled': emailNotificationsEnabled,
      'marketing_emails_enabled': marketingEmailsEnabled,
    };
  }

  SettingsModel copyWith({
    bool? allowMessages,
    bool? showEmail,
    bool? pushNotificationsEnabled,
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyFollows,
    bool? notifyFollowRequests,
    bool? notifyMessages,
    bool? notifyMentions,
    bool? emailNotificationsEnabled,
    bool? marketingEmailsEnabled,
    bool? isPrivate,
    String? accountStatus,
  }) {
    return SettingsModel(
      allowMessages: allowMessages ?? this.allowMessages,
      showEmail: showEmail ?? this.showEmail,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyComments: notifyComments ?? this.notifyComments,
      notifyFollows: notifyFollows ?? this.notifyFollows,
      notifyFollowRequests: notifyFollowRequests ?? this.notifyFollowRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyMentions: notifyMentions ?? this.notifyMentions,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      marketingEmailsEnabled:
          marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      isPrivate: isPrivate ?? this.isPrivate,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return fallback;
  }
}
