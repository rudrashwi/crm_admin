import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/notification_provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/ui/widgets/dashboard/stats_card.dart';
import 'package:crm_admin/ui/screens/leads/batch_assign_leads_screen.dart';
import 'package:crm_admin/ui/screens/user_management/view_users_screen.dart';
import 'package:crm_admin/ui/screens/leads/view_leads_screen.dart';
import 'package:crm_admin/ui/screens/reports/generate_report_screen.dart';
import 'package:crm_admin/ui/screens/notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedYear;
  int? _selectedMonth; // 1-12, null = all
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardStats();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notifProvider.unreadCount > 99
                              ? '99+'
                              : notifProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: () => context.read<DashboardProvider>().fetchDashboardStats(),
          // ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final stats = provider.stats;
          if (stats == null) {
            return const Center(child: Text('No data available'));
          }

          final users = Provider.of<UserProvider>(context).users;
          final roleCounts = <String, int>{};
          for (var u in users) {
            roleCounts[u.role] = (roleCounts[u.role] ?? 0) + 1;
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchDashboardStats();
              await Provider.of<UserProvider>(
                context,
                listen: false,
              ).fetchUsers();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  //           const SizedBox(height: 8),
                  //           Text('Last updated: ${stats.lastUpdated}', style: const TextStyle(color: AppColors.textSecondary)),
                  //         ],
                  //       ),
                  //     ),
                  //     IconButton(
                  //       icon: const Icon(Icons.refresh),
                  //       onPressed: () => provider.fetchDashboardStats(),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 12),

                  // Top stat cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 800
                        ? 4
                        : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.0,
                    children: [
                      StatsCard(
                        title: PrefManager.getRole() == 'SUB_ADMIN'
                            ? 'Admin Leads'
                            : 'Total Leads',
                        value: stats.totalLeads.toString(),
                        icon: Icons.leaderboard,
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ViewLeadsScreen()),
                        ),
                      ),
                      StatsCard(
                        title: PrefManager.getRole() == 'SUB_ADMIN'
                            ? 'Admin Employees'
                            : 'Employees',
                        value: stats.totalEmployees.toString(),
                        icon: Icons.people,
                        color: AppColors.info,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewUsersScreen(),
                          ),
                        ),
                      ),
                      StatsCard(
                        title: 'Batch Assign',
                        value: 'Assign',
                        icon: Icons.batch_prediction,
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BatchAssignLeadsScreen(),
                          ),
                        ),
                      ),
                      // Show Reports only for ADMIN
                      if (PrefManager.getRole() == 'ADMIN')
                        StatsCard(
                          title: 'Reports',
                          value: 'Generate',
                          icon: Icons.assessment,
                          color: AppColors.warning,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GenerateReportScreen(),
                            ),
                          ),
                        )
                      else
                        StatsCard(
                          title: 'Employees',
                          value: stats.totalEmployees.toString(),
                          icon: Icons.people,
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewUsersScreen(),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Charts row
                  Wrap(
                    runSpacing: 1,
                    spacing: 1,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 900
                            ? (MediaQuery.of(context).size.width - 64) / 2
                            : MediaQuery.of(context).size.width - 2,
                        child: _PieCard(
                          title: 'Leads by Status',
                          data: stats.leadsByStatus,
                          colorMap: {
                            'NEW': AppColors.info,
                            'ASSIGNED': const Color.fromARGB(255, 166, 41, 255),
                            'IN_PROGRESS': AppColors.warning,
                            'CLOSED': AppColors.success,
                          },
                          legendBelow: true,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 900
                            ? (MediaQuery.of(context).size.width - 64) / 2
                            : MediaQuery.of(context).size.width - 2,
                        child: _HorizontalBarCard(
                          title: 'Team Roles',
                          data: {
                            'ADMIN': roleCounts['ADMIN'] ?? 0,
                            'SUB_ADMIN': roleCounts['SUB_ADMIN'] ?? 0,
                            'EMPLOYEE': roleCounts['EMPLOYEE'] ?? 0,
                          },
                          colorMap: {
                            'ADMIN': AppColors.primary,
                            'SUB_ADMIN': AppColors.warning,
                            'EMPLOYEE': AppColors.info,
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Trend chart
                  const Text(
                    'Leads Trend',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Year / Month selectors
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Row(
                      children: [
                        const Text('Filter: '),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final items =
                                stats.leadsCreatedTrend
                                    .map((e) => DateTime.tryParse(e.date))
                                    .where((d) => d != null)
                                    .map((d) => d!.year)
                                    .toSet()
                                    .toList()
                                  ..sort();
                            return DropdownButton<int?>(
                              value: _selectedYear,
                              hint: const Text('Year'),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ...items.map(
                                  (y) => DropdownMenuItem<int?>(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedYear = v),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int?>(
                          value: _selectedMonth,
                          hint: const Text('Month'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All'),
                            ),
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem<int?>(
                                value: m,
                                child: Text(_monthLabel(m)),
                              ),
                          ],
                          onChanged: (v) => setState(() => _selectedMonth = v),
                        ),
                        // const Spacer(),
                        // IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<DashboardProvider>().fetchDashboardStats()),
                      ],
                    ),
                  ),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        // Apply year/month filters if selected
                        final trendAll = stats.leadsCreatedTrend;
                        final filtered = trendAll.where((t) {
                          final dt = DateTime.tryParse(t.date);
                          if (dt == null) return true;
                          if (_selectedYear != null && dt.year != _selectedYear)
                            return false;
                          if (_selectedMonth != null &&
                              dt.month != _selectedMonth)
                            return false;
                          return true;
                        }).toList();

                        final trend = filtered;
                        final maxY = trend
                            .map((t) => t.count)
                            .fold<int>(0, (p, n) => n > p ? n : p);
                        final barGroups = trend.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.count.toDouble(),
                                color: AppColors.primary,
                                width: 18,
                              ),
                            ],
                          );
                        }).toList();

                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (maxY + 1).toDouble(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: Colors.grey.withOpacity(0.08),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    final items = trend;
                                    if (idx < 0 || idx >= items.length)
                                      return const SizedBox.shrink();
                                    final labelDate = DateTime.tryParse(
                                      items[idx].date,
                                    );
                                    if (labelDate == null)
                                      return const SizedBox.shrink();
                                    // Only show labels on 1st and 15th
                                    if (labelDate.day == 1 ||
                                        labelDate.day == 15) {
                                      return Text(
                                        '${labelDate.day}/${labelDate.month}',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: barGroups,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieSections(Map<String, int> data, Map<String, Color> colorMap) {
    // Helper: returns an empty Container, actual pie built below in _PieCard
    return Container();
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Map<String, Color> colorMap;
  final bool legendBelow;

  const _PieCard({
    required this.title,
    required this.data,
    required this.colorMap,
    this.legendBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (p, e) => p + e);
    final sections = data.entries.where((e) => e.value > 0).map((e) {
      final value = e.value.toDouble();
      final percent = total > 0 ? (e.value / total) * 100 : 0.0;
      return PieChartSectionData(
        value: value,
        color: colorMap[e.key] ?? AppColors.textSecondary,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'No data',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (legendBelow)
              Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 36,
                        sectionsSpace: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: data.entries.map((e) {
                      final color = colorMap[e.key] ?? AppColors.textSecondary;
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewLeadsScreen(statusFilter: e.key),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${e.value})',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 36,
                          sectionsSpace: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: data.entries.map((e) {
                          final color =
                              colorMap[e.key] ?? AppColors.textSecondary;
                          return InkWell(
                            onTap: () {
                              // Navigate to leads filtered by this status/key
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewLeadsScreen(statusFilter: e.key),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(int m) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (m < 1 || m > 12) return m.toString();
  return labels[m - 1];
}

class _HorizontalBarCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Map<String, Color> colorMap;

  const _HorizontalBarCard({
    required this.title,
    required this.data,
    required this.colorMap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal = entries
        .map((e) => e.value)
        .fold<int>(0, (p, n) => n > p ? n : p);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${data.values.fold<int>(0, (p, e) => p + e)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: entries.map((e) {
                final color = colorMap[e.key] ?? AppColors.textSecondary;
                final percent = maxVal > 0 ? e.value / maxVal : 0.0;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewUsersScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final barWidth = constraints.maxWidth * percent;
                              return Stack(
                                children: [
                                  Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: barWidth,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Text(
                            e.value.toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
