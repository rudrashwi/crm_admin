class SubscriptionRequest {
  final String id;
  final String tenantId;
  final String requestedBy;
  final int numSubAdmins;
  final int numEmployees;
  final int? durationMonths;
  final int? durationDays;
  final double estimatedCost;
  final String? notes;
  final String status; // PENDING, APPROVED, REJECTED
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;

  SubscriptionRequest({
    required this.id,
    required this.tenantId,
    required this.requestedBy,
    required this.numSubAdmins,
    required this.numEmployees,
    this.durationMonths,
    this.durationDays,
    required this.estimatedCost,
    this.notes,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequest(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      numSubAdmins: json['numSubAdmins'] ?? 0,
      numEmployees: json['numEmployees'] ?? 0,
      durationMonths: json['durationMonths'],
      durationDays: json['durationDays'],
      estimatedCost: (json['estimatedCost'] ?? 0.0).toDouble(),
      notes: json['notes'],
      status: json['status'] ?? '',
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  String get durationDisplay {
    if (durationMonths != null && durationMonths! > 0) {
      return durationMonths == 1 ? '1 month' : '$durationMonths months';
    } else if (durationDays != null && durationDays! > 0) {
      return durationDays == 7 ? '1 week' : '$durationDays days';
    }
    return 'N/A';
  }
}

class PricingData {
  final String id;
  final double subAdminPricePerDay;
  final double employeePricePerDay;
  final String? updatedBy;
  final String createdAt;
  final String updatedAt;

  PricingData({
    required this.id,
    required this.subAdminPricePerDay,
    required this.employeePricePerDay,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PricingData.fromJson(Map<String, dynamic> json) {
    return PricingData(
      id: json['id'] ?? '',
      subAdminPricePerDay: (json['subAdminPricePerDay'] ?? 0.0).toDouble(),
      employeePricePerDay: (json['employeePricePerDay'] ?? 0.0).toDouble(),
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  // Backward compatibility properties
  double get adminFee => 0.0; // No admin fee in new API
  double get subAdminPrice => subAdminPricePerDay;
  double get employeePrice => employeePricePerDay;
}

class CostEstimate {
  final double adminFee;
  final double subAdminsCost;
  final double employeesCost;
  final double totalCost;
  final String breakdown;

  CostEstimate({
    required this.adminFee,
    required this.subAdminsCost,
    required this.employeesCost,
    required this.totalCost,
    required this.breakdown,
  });

  factory CostEstimate.fromJson(Map<String, dynamic> json) {
    return CostEstimate(
      adminFee: (json['adminFee'] ?? 0.0).toDouble(),
      subAdminsCost: (json['subAdminsCost'] ?? 0.0).toDouble(),
      employeesCost: (json['employeesCost'] ?? 0.0).toDouble(),
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
      breakdown: json['breakdown'] ?? '',
    );
  }
}

class SubscriptionDetails {
  final String? subscriptionId;
  final String plan;
  final String planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysRemaining;
  final String remainingTime;
  final String? ownerName;
  final String? adminName;
  final SubscriptionLimits? limits;
  final SubscriptionUsage? usage;
  final SubscriptionRemaining? remaining;
  final bool expired;
  final bool isExpired;
  final bool isTrial;
  final String status;
  final SubscriptionTrialInfo? trialInfo;

  SubscriptionDetails({
    this.subscriptionId,
    required this.plan,
    required this.planName,
    this.startDate,
    this.endDate,
    required this.daysRemaining,
    required this.remainingTime,
    this.ownerName,
    this.adminName,
    this.limits,
    this.usage,
    this.remaining,
    required this.expired,
    required this.isExpired,
    required this.isTrial,
    required this.status,
    this.trialInfo,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      subscriptionId: json['subscriptionId'],
      plan: json['plan'] ?? '',
      planName: json['planName'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      daysRemaining: json['daysRemaining'] ?? 0,
      remainingTime: json['remainingTime'] ?? '',
      ownerName: json['ownerName'],
      adminName: json['adminName'],
      limits: json['limits'] != null
          ? SubscriptionLimits.fromJson(json['limits'])
          : null,
      usage: json['usage'] != null
          ? SubscriptionUsage.fromJson(json['usage'])
          : null,
      remaining: json['remaining'] != null
          ? SubscriptionRemaining.fromJson(json['remaining'])
          : null,
      expired: json['expired'] ?? json['isExpired'] ?? true,
      isExpired: json['isExpired'] ?? json['expired'] ?? true,
      isTrial: json['isTrial'] ?? false,
      status: json['status'] ?? '',
      trialInfo: json['trialInfo'] != null
          ? SubscriptionTrialInfo.fromJson(json['trialInfo'])
          : null,
    );
  }

  bool get isActive => !isExpired && status == 'ACTIVE';
}

class SubscriptionTrialInfo {
  final bool isTrialActive;
  final String message;

  SubscriptionTrialInfo({required this.isTrialActive, required this.message});

  factory SubscriptionTrialInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionTrialInfo(
      isTrialActive: json['isTrialActive'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class SubscriptionLimits {
  final int employees;
  final int subAdmins;
  final int leads;

  SubscriptionLimits({
    required this.employees,
    required this.subAdmins,
    required this.leads,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) {
    return SubscriptionLimits(
      employees: json['employees'] ?? 0,
      subAdmins: json['subAdmins'] ?? 0,
      leads: json['leads'] ?? 0,
    );
  }
}

class SubscriptionUsage {
  final int employees;
  final int subAdmins;
  final int leads;

  SubscriptionUsage({
    required this.employees,
    required this.subAdmins,
    required this.leads,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsage(
      employees: json['employees'] ?? 0,
      subAdmins: json['subAdmins'] ?? 0,
      leads: json['leads'] ?? 0,
    );
  }
}

class SubscriptionRemaining {
  final int employees;
  final int subAdmins;

  SubscriptionRemaining({required this.employees, required this.subAdmins});

  factory SubscriptionRemaining.fromJson(Map<String, dynamic> json) {
    return SubscriptionRemaining(
      employees: json['employees'] ?? 0,
      subAdmins: json['subAdmins'] ?? 0,
    );
  }
}

class RenewalRequest {
  final String id;
  final String tenantId;
  final String userId;
  final String username;
  final String subscriptionId;
  final String planName;
  final String status;
  final String requestedAt;
  final String? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  RenewalRequest({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.username,
    required this.subscriptionId,
    required this.planName,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  factory RenewalRequest.fromJson(Map<String, dynamic> json) {
    return RenewalRequest(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      approvedAt: json['approvedAt'],
      approvedBy: json['approvedBy'],
      rejectionReason: json['rejectionReason'],
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
