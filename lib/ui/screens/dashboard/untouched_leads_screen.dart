import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';

class UntouchedLeadsScreen extends StatelessWidget {
  const UntouchedLeadsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Color _getDaysSinceAssignedColor(int days) {
    if (days >= 7) return Colors.red;
    if (days >= 3) return Colors.orange;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Untouched Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().fetchDashboardStats(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchDashboardStats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.stats;
          if (stats == null || stats.untouchedLeadsList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'No Untouched Leads',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All assigned leads have been contacted!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchDashboardStats(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              children: [
                // Header Card
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.timer_off_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.untouchedLeads} Untouched Leads',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'These leads have been assigned but not yet contacted',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Untouched Leads List
                ...stats.untouchedLeadsList.map((lead) {
                  final dayColor = _getDaysSinceAssignedColor(lead.daysSinceAssigned);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200, width: 1),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeadDetailScreen(leadId: lead.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: dayColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lead.customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              lead.contactPhone,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.phone, size: 20, color: AppColors.success),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _makePhoneCall(lead.contactPhone),
                                            tooltip: 'Call ${lead.customerName}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: dayColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: dayColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${lead.daysSinceAssigned}d',
                                        style: TextStyle(
                                          color: dayColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assigned To',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lead.assignedEmployeeName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (lead.assignedEmployeePhone != null && lead.assignedEmployeePhone!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.phone, size: 20, color: AppColors.success),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _makePhoneCall(lead.assignedEmployeePhone!),
                                      tooltip: 'Call ${lead.assignedEmployeeName}',
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assigned Date',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lead.assignedDate,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
