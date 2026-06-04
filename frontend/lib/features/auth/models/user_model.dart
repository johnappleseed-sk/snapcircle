class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;
  final String? provider;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
    this.provider,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
      provider: json['provider']?.toString(),
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
    };
  }

  static int _parseId(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
