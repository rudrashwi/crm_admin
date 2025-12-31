import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';

class ViewLeadsScreen extends StatefulWidget {
  const ViewLeadsScreen({super.key});

  @override
  State<ViewLeadsScreen> createState() => _ViewLeadsScreenState();
}

class _ViewLeadsScreenState extends State<ViewLeadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().fetchLeads();
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LeadsProvider>().fetchLeads(),
          ),
        ],
      ),
      body: Consumer<LeadsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.leads.isEmpty) {
            return const Center(child: Text('No leads found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.leads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lead = provider.leads[index];
              return Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  title: Text(lead.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lead.status, style: TextStyle(color: _getStatusColor(lead.status), fontWeight: FontWeight.bold, fontSize: 12)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(Icons.phone, lead.contactPhone),
                          _infoRow(Icons.email, lead.email),
                          _infoRow(Icons.message, lead.requirementMessage),
                          _infoRow(Icons.person, lead.assignedEmployeeName ?? 'Unassigned'),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Assign'),
                                onPressed: () => _showAssignDialog(context, lead.id),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Update'),
                                onPressed: () => _showUpdateDialog(context, lead.id, lead.status),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => _showDeleteConfirm(context, lead.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW': return AppColors.info;
      case 'IN_PROGRESS': return AppColors.warning;
      case 'CLOSED': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  void _showAssignDialog(BuildContext context, String leadId) {
    final users = context.read<UserProvider>().users.where((u) => u.role == 'EMPLOYEE').toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Lead'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(users[index].fullName),
              onTap: () async {
                final success = await context.read<LeadsProvider>().assignLead(leadId, users[index].id);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead assigned')));
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, String leadId, String currentStatus) {
    String selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: DropdownButtonFormField<String>(
          value: currentStatus,
          items: const [
            DropdownMenuItem(value: 'NEW', child: Text('New')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
            DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
          ],
          onChanged: (v) => selectedStatus = v!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().updateLead(leadId, {'status': selectedStatus});
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String leadId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: const Text('Are you sure you want to delete this lead?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().deleteLead(leadId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
