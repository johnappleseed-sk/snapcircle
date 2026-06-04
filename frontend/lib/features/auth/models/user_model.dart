class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;
  final String? provider;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowedByMe;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
    this.provider,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowedByMe = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: _parseAvatar(json),
      bio: json['bio']?.toString(),
      provider: json['provider']?.toString(),
      postsCount: _parseInt(json['posts_count']),
      followersCount: _parseInt(json['followers_count']),
      followingCount: _parseInt(json['following_count']),
      isFollowedByMe: _parseBool(json['is_followed_by_me']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'provider': provider,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_followed_by_me': isFollowedByMe,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? bio,
    String? provider,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowedByMe,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      provider: provider ?? this.provider,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
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

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }
}
