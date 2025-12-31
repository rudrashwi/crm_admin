import '../auth/user_model.dart';
import '../leads/lead_model.dart';

class EmployeeDetail {
  final String employeeId;
  final String employeeName;
  final String email;
  final String role;
  final bool isActive;
  final int totalAssignedLeads;
  final int activeLeads;
  final int closedLeads;
  final double conversionRate;
  final List<LeadModel> recentLeads;
  final String? managerId;
  final String? managerName;

  EmployeeDetail({
    required this.employeeId,
    required this.employeeName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.totalAssignedLeads,
    required this.activeLeads,
    required this.closedLeads,
    required this.conversionRate,
    required this.recentLeads,
    this.managerId,
    this.managerName,
  });

  factory EmployeeDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeDetail(
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? false,
      totalAssignedLeads: json['totalAssignedLeads'] ?? 0,
      activeLeads: json['activeLeads'] ?? 0,
      closedLeads: json['closedLeads'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      recentLeads: (json['recentLeads'] as List? ?? [])
          .map((e) => LeadModel.fromJson(e))
          .toList(),
      managerId: json['managerId'],
      managerName: json['managerName'],
    );
  }
}
