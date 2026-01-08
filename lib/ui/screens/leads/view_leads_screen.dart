import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/ui/screens/leads/select_employee_screen.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';
import 'package:crm_admin/ui/screens/leads/add_remark_screen.dart';

class ViewLeadsScreen extends StatefulWidget {
  final String? statusFilter;
  const ViewLeadsScreen({super.key, this.statusFilter});

  @override
  State<ViewLeadsScreen> createState() => _ViewLeadsScreenState();
}

class _ViewLeadsScreenState extends State<ViewLeadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().fetchLeads();
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

          // Apply optional status filter
          var leads = widget.statusFilter == null
              ? provider.leads
              : provider.leads
                    .where((l) => l.status == widget.statusFilter)
                    .toList();

          // Reverse order to show newest first (bottom items at top)
          leads = leads.reversed.toList();

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            leads = leads.where((lead) {
              final query = _searchQuery.toLowerCase();
              return lead.customerName.toLowerCase().contains(query) ||
                  lead.contactPhone.toLowerCase().contains(query) ||
                  lead.email.toLowerCase().contains(query) ||
                  lead.requirementMessage.toLowerCase().contains(query) ||
                  (lead.assignedEmployeeName?.toLowerCase().contains(query) ??
                      false);
            }).toList();
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, email...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              // Leads List
              if (leads.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No leads found matching "$_searchQuery"'
                          : 'No leads found${widget.statusFilter != null ? ' (${widget.statusFilter})' : ''}',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: leads.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lead = leads[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeadDetailScreen(leadId: lead.id),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Leading Icon
                                CircleAvatar(
                                  backgroundColor: AppColors.accent,
                                  radius: 24,
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Lead Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lead.customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lead.contactPhone,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            lead.status,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              lead.status,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          lead.status,
                                          style: TextStyle(
                                            color: _getStatusColor(lead.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Options Menu Icon
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () =>
                                      _showLeadOptions(context, lead),
                                  tooltip: 'Options',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showLeadOptions(BuildContext context, dynamic lead) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    radius: 20,
                    child: Icon(Icons.business, color: Colors.white, size: 20),
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
                        Text(
                          lead.contactPhone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Options
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeadDetailScreen(leadId: lead.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment, color: AppColors.info),
              title: const Text('Add Remark'),
              onTap: () {
                Navigator.pop(context);
                _navigateToRemark(context, lead);
              },
            ),
            if (lead.assignedEmployeeId == null ||
                lead.assignedEmployeeId!.isEmpty)
              ListTile(
                leading: const Icon(Icons.person_add, color: AppColors.success),
                title: const Text('Assign to Employee'),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignDialog(context, lead.id);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.person_remove,
                  color: AppColors.warning,
                ),
                title: const Text('Unassign Employee'),
                subtitle: Text(lead.assignedEmployeeName ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _showUnassignConfirm(
                    context,
                    lead.id,
                    lead.assignedEmployeeName ?? 'employee',
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.accent),
              title: const Text('Update Status'),
              onTap: () {
                Navigator.pop(context);
                _showUpdateDialog(context, lead.id, lead.status);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Lead'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, lead.id);
              },
            ),
          ],
        ),
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

  Widget _infoRowWithActions(
    IconData icon,
    String text, {
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          if (isPhone) ..._buildPhoneActions(text),
          if (isEmail) _buildEmailAction(text),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneActions(String phone) {
    return [
      IconButton(
        onPressed: () => _makeCall(phone),
        icon: const Icon(Icons.call, color: AppColors.success, size: 18),
        tooltip: 'Call',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 6),
      IconButton(
        onPressed: () => _openWhatsApp(phone),
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Color(0xFF25D366),
          size: 18,
        ),
        tooltip: 'WhatsApp',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ];
  }

  Widget _buildEmailAction(String email) {
    return IconButton(
      onPressed: () => _openEmail(email),
      icon: const Icon(Icons.email, color: AppColors.primary, size: 18),
      tooltip: 'Send Email',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.info;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'CLOSED':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAssignDialog(BuildContext context, String leadId) {
    final lead = context.read<LeadsProvider>().leads.firstWhere(
      (l) => l.id == leadId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectEmployeeScreen(
          leadId: leadId,
          leadCustomerName: lead.customerName,
          assignedEmployeeId: lead.assignedEmployeeId,
          assignedEmployeeName: lead.assignedEmployeeName,
        ),
      ),
    );
  }

  void _showUpdateDialog(
    BuildContext context,
    String leadId,
    String currentStatus,
  ) {
    String selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Status'),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: 'NEW', child: Text('New')),
              DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
              DropdownMenuItem(
                value: 'IN_PROGRESS',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
            ],
            onChanged: (v) => setState(() => selectedStatus = v!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await context.read<LeadsProvider>().updateLead(
                  leadId,
                  {'status': selectedStatus},
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated')),
                  );
                  // Refresh dashboard stats after lead update
                  // Refresh dashboard stats after lead update
                  try {
                    context.read<DashboardProvider>().fetchDashboardStats();
                  } catch (_) {}
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().deleteLead(
                leadId,
              );
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Lead deleted')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnassignConfirm(
    BuildContext context,
    String leadId,
    String employeeName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Lead'),
        content: Text(
          'Are you sure you want to unassign this lead from $employeeName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().unassignLead(
                leadId,
              );
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lead unassigned successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to unassign lead'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Unassign',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: ${phone}')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final uri = Uri.parse('https://wa.me/$cleanPhone');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Make sure it is installed.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openEmail(String email) async {
    try {
      final uri = Uri(scheme: 'mailto', path: email);
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email app. Make sure one is installed.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _navigateToRemark(BuildContext context, dynamic lead) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRemarkScreen(
          leadId: lead.id,
          leadName: lead.customerName,
          phoneNumber: lead.contactPhone,
        ),
      ),
    );

    // Refresh leads if remark was added successfully
    if (result == true && mounted) {
      context.read<LeadsProvider>().fetchLeads();
    }
  }
}
