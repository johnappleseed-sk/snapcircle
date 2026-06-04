import 'user_model.dart';

class AuthResponse {
  final UserModel user;
  final String token;
  final String tokenType;

  const AuthResponse({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final responseData = data is Map<String, dynamic> ? data : json;
    final userJson = responseData['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Login response did not include a user.');
    }

    final token = responseData['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Login response did not include a token.');
    }

    return AuthResponse(
      user: UserModel.fromJson(userJson),
      token: token,
      tokenType: responseData['token_type']?.toString() ?? 'Bearer',
    );
  }
}
