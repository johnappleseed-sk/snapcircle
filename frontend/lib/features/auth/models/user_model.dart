class UserModel {
  final int id;
  final String name;
  final String email;
  final String? username;
  final String? avatar;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? bio;
  final String? provider;
  final String? location;
  final String? website;
  final bool isPrivate;
  final bool allowMessages;
  final bool showEmail;
  final String accountStatus;
  final String role;
  final DateTime? joinedAt;
  final DateTime? lastActiveAt;
  final int profileCompletion;
  final bool isMe;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowedByMe;
  final bool hasRequestedFollow;
  final String followStatus;
  final bool isBlockedByMe;
  final bool hasBlockedMe;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.avatar,
    this.avatarUrl,
    this.coverImageUrl,
    this.bio,
    this.provider,
    this.location,
    this.website,
    this.isPrivate = false,
    this.allowMessages = true,
    this.showEmail = false,
    this.accountStatus = 'active',
    this.role = 'user',
    this.joinedAt,
    this.lastActiveAt,
    this.profileCompletion = 0,
    this.isMe = false,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowedByMe = false,
    this.hasRequestedFollow = false,
    this.followStatus = 'not_following',
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: _parseString(json['username']),
      avatar: _parseAvatar(json),
      avatarUrl: _parseString(json['avatar_url']) ?? _parseAvatar(json),
      coverImageUrl: _parseCoverImageUrl(json),
      bio: json['bio']?.toString(),
      provider: json['provider']?.toString(),
      location: _parseString(json['location']),
      website: _parseString(json['website']),
      isPrivate: _parseBool(json['is_private']),
      allowMessages: _parseBool(json['allow_messages'], fallback: true),
      showEmail: _parseBool(json['show_email']),
      accountStatus: _parseString(json['account_status']) ?? 'active',
      role: _parseString(json['role']) ?? 'user',
      joinedAt: _parseDate(json['joined_at'] ?? json['created_at']),
      lastActiveAt: _parseDate(json['last_active_at']),
      profileCompletion: _parseInt(json['profile_completion']),
      isMe: _parseBool(json['is_me']),
      postsCount: _parseInt(json['posts_count']),
      followersCount: _parseInt(json['followers_count']),
      followingCount: _parseInt(json['following_count']),
      isFollowedByMe: _parseBool(json['is_followed_by_me']),
      hasRequestedFollow: _parseBool(json['has_requested_follow']),
      followStatus: _parseString(json['follow_status']) ?? 'not_following',
      isBlockedByMe: _parseBool(json['is_blocked_by_me']),
      hasBlockedMe: _parseBool(json['has_blocked_me']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'cover_image_url': coverImageUrl,
      'bio': bio,
      'provider': provider,
      'location': location,
      'website': website,
      'is_private': isPrivate,
      'allow_messages': allowMessages,
      'show_email': showEmail,
      'account_status': accountStatus,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'profile_completion': profileCompletion,
      'is_me': isMe,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_followed_by_me': isFollowedByMe,
      'has_requested_follow': hasRequestedFollow,
      'follow_status': followStatus,
      'is_blocked_by_me': isBlockedByMe,
      'has_blocked_me': hasBlockedMe,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? avatar,
    String? avatarUrl,
    String? coverImageUrl,
    String? bio,
    String? provider,
    String? location,
    String? website,
    bool? isPrivate,
    bool? allowMessages,
    bool? showEmail,
    String? accountStatus,
    String? role,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    int? profileCompletion,
    bool? isMe,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowedByMe,
    bool? hasRequestedFollow,
    String? followStatus,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bio: bio ?? this.bio,
      provider: provider ?? this.provider,
      location: location ?? this.location,
      website: website ?? this.website,
      isPrivate: isPrivate ?? this.isPrivate,
      allowMessages: allowMessages ?? this.allowMessages,
      showEmail: showEmail ?? this.showEmail,
      accountStatus: accountStatus ?? this.accountStatus,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      isMe: isMe ?? this.isMe,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      hasRequestedFollow: hasRequestedFollow ?? this.hasRequestedFollow,
      followStatus: followStatus ?? this.followStatus,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
    );
  }

  static int _parseId(dynamic value) {
    return _parseInt(value);
  }

  static String? _parseAvatar(Map<String, dynamic> json) {
    final avatar = json['avatar_url'] ?? json['avatar'] ?? json['photo'];
    final avatarValue = avatar?.toString();
    return avatarValue == null || avatarValue.isEmpty ? null : avatarValue;
  }

  static String? _parseCoverImageUrl(Map<String, dynamic> json) {
    return _parseString(json['cover_image_url'] ?? json['cover_image']);
  }

  static String? _parseString(dynamic value) {
    final parsed = value?.toString();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
