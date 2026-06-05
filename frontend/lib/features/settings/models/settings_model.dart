class SettingsModel {
  final bool allowMessages;
  final bool showEmail;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool marketingEmailsEnabled;
  final String accountStatus;

  const SettingsModel({
    this.allowMessages = true,
    this.showEmail = false,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    this.marketingEmailsEnabled = false,
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
      emailNotificationsEnabled: _parseBool(
        json['email_notifications_enabled'],
      ),
      marketingEmailsEnabled: _parseBool(json['marketing_emails_enabled']),
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
      'email_notifications_enabled': emailNotificationsEnabled,
      'marketing_emails_enabled': marketingEmailsEnabled,
      'account_status': accountStatus,
    };
  }

  Map<String, dynamic> toSettingsUpdateJson() {
    return {
      'allow_messages': allowMessages,
      'show_email': showEmail,
      'push_notifications_enabled': pushNotificationsEnabled,
      'email_notifications_enabled': emailNotificationsEnabled,
      'marketing_emails_enabled': marketingEmailsEnabled,
    };
  }

  SettingsModel copyWith({
    bool? allowMessages,
    bool? showEmail,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? marketingEmailsEnabled,
    String? accountStatus,
  }) {
    return SettingsModel(
      allowMessages: allowMessages ?? this.allowMessages,
      showEmail: showEmail ?? this.showEmail,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      marketingEmailsEnabled:
          marketingEmailsEnabled ?? this.marketingEmailsEnabled,
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
