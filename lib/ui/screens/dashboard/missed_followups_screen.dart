import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';

class MissedFollowupsScreen extends StatelessWidget {
  const MissedFollowupsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missed Follow-ups'),
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
          if (stats == null || stats.missedFollowUpsList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'No Missed Follow-ups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All follow-ups are up to date!',
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
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.missedFollowUps} Missed Follow-ups',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Employees missed these scheduled follow-ups',
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

                // Follow-ups List
                ...stats.missedFollowUpsList.map((followUp) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200, width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeadDetailScreen(leadId: followUp.leadId),
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
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            followUp.leadName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (followUp.leadPhone != null && followUp.leadPhone!.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.phone, size: 18, color: AppColors.success),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _makePhoneCall(followUp.leadPhone!),
                                              tooltip: 'Call Lead',
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            followUp.employeeName,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (followUp.employeePhone != null && followUp.employeePhone!.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.phone, size: 16, color: AppColors.info),
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _makePhoneCall(followUp.employeePhone!),
                                              tooltip: 'Call Employee',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Scheduled Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        followUp.scheduledDateTime,
                                        style: const TextStyle(
                                          color: Colors.red,
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
                          if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notes, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Notes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          followUp.notes!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
