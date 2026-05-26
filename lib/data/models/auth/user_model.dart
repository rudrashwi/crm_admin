class TrialInfo {
  final bool hasUsedTrial;
  final bool? isTrialActive;
  final bool isEligible;
  final bool? mobileUsed;
  final bool? accountUsed;
  final String? reason;
  final String message;

  TrialInfo({
    required this.hasUsedTrial,
    this.isTrialActive,
    required this.isEligible,
    this.mobileUsed,
    this.accountUsed,
    this.reason,
    required this.message,
  });

  factory TrialInfo.fromJson(Map<String, dynamic> json) {
    return TrialInfo(
      hasUsedTrial: json['hasUsedTrial'] ?? false,
      isTrialActive: json['isTrialActive'],
      isEligible: json['isEligible'] ?? false,
      mobileUsed: json['mobileUsed'],
      accountUsed: json['accountUsed'],
      reason: json['reason'],
      message: json['message'] ?? '',
    );
  }
}

class OwnerSubscription {
  final String? id;
  final String planName;
  final String status;
  final String? startDate;
  final String? endDate;
  final bool isExpired;
  final bool isTrial;

  OwnerSubscription({
    this.id,
    required this.planName,
    required this.status,
    this.startDate,
    this.endDate,
    required this.isExpired,
    required this.isTrial,
  });

  factory OwnerSubscription.fromJson(Map<String, dynamic> json) {
    return OwnerSubscription(
      id: json['id'],
      planName: json['planName'] ?? '',
      status: json['status'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
      isExpired: json['isExpired'] ?? false,
      isTrial: json['isTrial'] ?? false,
    );
  }
}

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
  final String? mobileNumber;
  final bool isActive;
  final bool canCreateLeads;
  final String? createdAt;
  final String? lastLogin;
  final TrialInfo? trialInfo;
  final OwnerSubscription? ownerSubscription;

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
    this.mobileNumber,
    required this.isActive,
    this.canCreateLeads = false,
    this.createdAt,
    this.lastLogin,
    this.trialInfo,
    this.ownerSubscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    final username =
        json['username'] ??
        (email.isNotEmpty ? email.split('@')[0] : 'unknown');

    return UserModel(
      id: json['userId'] ?? json['id'] ?? json['employeeId'] ?? '',
      username: username,
      email: email,
      fullName: json['fullName'] ?? json['employeeName'] ?? 'Unknown',
      role: json['role'] ?? '',
      tenantId: json['tenantId'] ?? '',
      companyName: json['companyName'] ?? '',
      managerId: json['managerId'],
      managerName: json['managerName'],
      mobileNumber: json['mobileNumber'],
      isActive: json['isActive'] ?? false,
      canCreateLeads: json['canCreateLeads'] ?? false,
      createdAt: json['createdAt'],
      lastLogin: json['lastLogin'],
      trialInfo: json['trialInfo'] != null
          ? TrialInfo.fromJson(json['trialInfo'])
          : null,
      ownerSubscription: json['ownerSubscription'] != null
          ? OwnerSubscription.fromJson(json['ownerSubscription'])
          : null,
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
