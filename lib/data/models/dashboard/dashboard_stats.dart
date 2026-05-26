class DashboardStats {
  final int totalLeads;
  final int newLeads;
  final int inProgressLeads;
  final int closedLeads;
  final int unassignedLeads;
  final int missedFollowUps;
  final List<MissedFollowUp> missedFollowUpsList;
  final int untouchedLeads;
  final List<UntouchedLead> untouchedLeadsList;
  final double conversionRate;
  final double averageClosingTime;
  final int totalEmployees;
  final int activeEmployees;
  final int? totalSubAdmins;
  final Map<String, int> leadsBySource;
  final Map<String, int> leadsByStatus;
  final int leadsCreatedToday;
  final int leadsCreatedThisWeek;
  final int leadsCreatedThisMonth;
  final int leadsClosedToday;
  final int leadsClosedThisWeek;
  final int leadsClosedThisMonth;
  final List<TopPerformer> topPerformers;
  final List<TrendData> leadsCreatedTrend;
  final List<TrendData> leadsClosedTrend;
  final String lastUpdated;

  DashboardStats({
    required this.totalLeads,
    required this.newLeads,
    required this.inProgressLeads,
    required this.closedLeads,
    required this.unassignedLeads,
    required this.missedFollowUps,
    required this.missedFollowUpsList,
    required this.untouchedLeads,
    required this.untouchedLeadsList,
    required this.conversionRate,
    required this.averageClosingTime,
    required this.totalEmployees,
    required this.activeEmployees,
    this.totalSubAdmins,
    required this.leadsBySource,
    required this.leadsByStatus,
    required this.leadsCreatedToday,
    required this.leadsCreatedThisWeek,
    required this.leadsCreatedThisMonth,
    required this.leadsClosedToday,
    required this.leadsClosedThisWeek,
    required this.leadsClosedThisMonth,
    required this.topPerformers,
    required this.leadsCreatedTrend,
    required this.leadsClosedTrend,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalLeads: json['totalLeads'] ?? 0,
      newLeads: json['newLeads'] ?? 0,
      inProgressLeads: json['inProgressLeads'] ?? 0,
      closedLeads: json['closedLeads'] ?? 0,
      unassignedLeads: json['unassignedLeads'] ?? 0,
      missedFollowUps: json['missedFollowUps'] ?? 0,
      missedFollowUpsList: (json['missedFollowUpsList'] as List? ?? [])
          .map((e) => MissedFollowUp.fromJson(e))
          .toList(),
      untouchedLeads: json['untouchedLeads'] ?? 0,
      untouchedLeadsList: (json['untouchedLeadsList'] as List? ?? [])
          .map((e) => UntouchedLead.fromJson(e))
          .toList(),
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      averageClosingTime: (json['averageClosingTime'] ?? 0).toDouble(),
      totalEmployees: json['totalEmployees'] ?? 0,
      activeEmployees: json['activeEmployees'] ?? 0,
      totalSubAdmins: json['totalSubAdmins'],
      leadsBySource: Map<String, int>.from(json['leadsBySource'] ?? {}),
      leadsByStatus: Map<String, int>.from(json['leadsByStatus'] ?? {}),
      leadsCreatedToday: json['leadsCreatedToday'] ?? 0,
      leadsCreatedThisWeek: json['leadsCreatedThisWeek'] ?? 0,
      leadsCreatedThisMonth: json['leadsCreatedThisMonth'] ?? 0,
      leadsClosedToday: json['leadsClosedToday'] ?? 0,
      leadsClosedThisWeek: json['leadsClosedThisWeek'] ?? 0,
      leadsClosedThisMonth: json['leadsClosedThisMonth'] ?? 0,
      topPerformers: (json['topPerformers'] as List? ?? [])
          .map((e) => TopPerformer.fromJson(e))
          .toList(),
      leadsCreatedTrend: (json['leadsCreatedTrend'] as List? ?? [])
          .map((e) => TrendData.fromJson(e))
          .toList(),
      leadsClosedTrend: (json['leadsClosedTrend'] as List? ?? [])
          .map((e) => TrendData.fromJson(e))
          .toList(),
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

class MissedFollowUp {
  final String id;
  final String leadId;
  final String leadName;
  final String? leadPhone;
  final String employeeId;
  final String employeeName;
  final String? employeePhone;
  final String scheduledDateTime;
  final String? notes;

  MissedFollowUp({
    required this.id,
    required this.leadId,
    required this.leadName,
    this.leadPhone,
    required this.employeeId,
    required this.employeeName,
    this.employeePhone,
    required this.scheduledDateTime,
    this.notes,
  });

  factory MissedFollowUp.fromJson(Map<String, dynamic> json) {
    return MissedFollowUp(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      leadName: json['leadName'] ?? '',
      leadPhone: json['leadPhone'],
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeePhone: json['employeePhone'],
      scheduledDateTime: json['scheduledDateTime'] ?? '',
      notes: json['notes'],
    );
  }
}

class UntouchedLead {
  final String id;
  final String customerName;
  final String contactPhone;
  final String assignedEmployeeId;
  final String assignedEmployeeName;
  final String? assignedEmployeePhone;
  final String assignedDate;
  final int daysSinceAssigned;

  UntouchedLead({
    required this.id,
    required this.customerName,
    required this.contactPhone,
    required this.assignedEmployeeId,
    required this.assignedEmployeeName,
    this.assignedEmployeePhone,
    required this.assignedDate,
    required this.daysSinceAssigned,
  });

  factory UntouchedLead.fromJson(Map<String, dynamic> json) {
    return UntouchedLead(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      assignedEmployeeId: json['assignedEmployeeId'] ?? '',
      assignedEmployeeName: json['assignedEmployeeName'] ?? '',
      assignedEmployeePhone: json['assignedEmployeePhone'],
      assignedDate: json['assignedDate'] ?? '',
      daysSinceAssigned: json['daysSinceAssigned'] ?? 0,
    );
  }
}

class TopPerformer {
  final String employeeId;
  final String employeeName;
  final int assignedLeads;
  final int closedLeads;
  final double conversionRate;
  final double? averageResponseTime;

  TopPerformer({
    required this.employeeId,
    required this.employeeName,
    required this.assignedLeads,
    required this.closedLeads,
    required this.conversionRate,
    this.averageResponseTime,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      assignedLeads: json['assignedLeads'] ?? 0,
      closedLeads: json['closedLeads'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      averageResponseTime: json['averageResponseTime'] != null
          ? (json['averageResponseTime'] as num).toDouble()
          : null,
    );
  }
}

class TrendData {
  final String date;
  final int count;

  TrendData({required this.date, required this.count});

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
