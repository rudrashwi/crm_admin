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
          .map((e) {
            // Map leadId to id for LeadModel compatibility
            if (e['leadId'] != null && e['id'] == null) {
              e['id'] = e['leadId'];
            }
            // Map assignedAt to createdAt and lastUpdated to updatedAt
            if (e['assignedAt'] != null && e['createdAt'] == null) {
              e['createdAt'] = e['assignedAt'];
            }
            if (e['lastUpdated'] != null && e['updatedAt'] == null) {
              e['updatedAt'] = e['lastUpdated'];
            }
            // Ensure required fields have defaults
            e['tenantId'] ??= '';
            e['contactPhone'] ??= '';
            e['email'] ??= '';
            e['requirementMessage'] ??= '';
            e['source'] ??= '';
            e['createdBy'] ??= '';
            return LeadModel.fromJson(e);
          })
          .toList(),
      managerId: json['managerId'],
      managerName: json['managerName'],
    );
  }

  EmployeeDetail copyWith({
    String? employeeId,
    String? employeeName,
    String? email,
    String? role,
    bool? isActive,
    int? totalAssignedLeads,
    int? activeLeads,
    int? closedLeads,
    double? conversionRate,
    List<LeadModel>? recentLeads,
    String? managerId,
    String? managerName,
  }) {
    return EmployeeDetail(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      totalAssignedLeads: totalAssignedLeads ?? this.totalAssignedLeads,
      activeLeads: activeLeads ?? this.activeLeads,
      closedLeads: closedLeads ?? this.closedLeads,
      conversionRate: conversionRate ?? this.conversionRate,
      recentLeads: recentLeads ?? this.recentLeads,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
    );
  }
}
