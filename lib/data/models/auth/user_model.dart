class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String tenantId;
  final String companyName;
  final String? managerId;
  final String? managerName;
  final bool isActive;
  final String? createdAt;
  final String? lastLogin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.tenantId,
    required this.companyName,
    this.managerId,
    this.managerName,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      tenantId: json['tenantId'] ?? '',
      companyName: json['companyName'] ?? '',
      managerId: json['managerId'],
      managerName: json['managerName'],
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'],
      lastLogin: json['lastLogin'],
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      user: UserModel.fromJson(json),
    );
  }
}

class UsernameCheckResponse {
  final bool available;
  final String username;
  final String message;
  final List<String> suggestions;

  UsernameCheckResponse({
    required this.available,
    required this.username,
    required this.message,
    required this.suggestions,
  });

  factory UsernameCheckResponse.fromJson(Map<String, dynamic> json) {
    return UsernameCheckResponse(
      available: json['available'] ?? false,
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}
