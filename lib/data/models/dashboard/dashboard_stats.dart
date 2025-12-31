class DashboardStats {
  final int totalLeads;
  final int newLeads;
  final int inProgressLeads;
  final int closedLeads;
  final int unassignedLeads;
  final double conversionRate;
  final double averageClosingTime;
  final int totalEmployees;
  final Map<String, int> leadsBySource;
  final Map<String, int> leadsByStatus;
  final List<TrendData> leadsCreatedTrend;
  final String lastUpdated;

  DashboardStats({
    required this.totalLeads,
    required this.newLeads,
    required this.inProgressLeads,
    required this.closedLeads,
    required this.unassignedLeads,
    required this.conversionRate,
    required this.averageClosingTime,
    required this.totalEmployees,
    required this.leadsBySource,
    required this.leadsByStatus,
    required this.leadsCreatedTrend,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalLeads: json['totalLeads'] ?? 0,
      newLeads: json['newLeads'] ?? 0,
      inProgressLeads: json['inProgressLeads'] ?? 0,
      closedLeads: json['closedLeads'] ?? 0,
      unassignedLeads: json['unassignedLeads'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      averageClosingTime: (json['averageClosingTime'] ?? 0).toDouble(),
      totalEmployees: json['totalEmployees'] ?? 0,
      leadsBySource: Map<String, int>.from(json['leadsBySource'] ?? {}),
      leadsByStatus: Map<String, int>.from(json['leadsByStatus'] ?? {}),
      leadsCreatedTrend: (json['leadsCreatedTrend'] as List? ?? [])
          .map((e) => TrendData.fromJson(e))
          .toList(),
      lastUpdated: json['lastUpdated'] ?? '',
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
