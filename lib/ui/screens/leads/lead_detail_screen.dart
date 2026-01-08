import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/leads/lead_model.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/ui/screens/leads/select_employee_screen.dart';
import 'package:crm_admin/ui/screens/leads/add_remark_screen.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  bool _isLoading = true;
  String? _error;
  LeadModel? _lead;

  @override
  void initState() {
    super.initState();
    _fetchLeadDetails();
  }

  Future<void> _fetchLeadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        ApiEndpoints.getLeadDetails(widget.leadId),
      );
      setState(() {
        _lead = LeadModel.fromJson(response.data['data']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.info;
      case 'ASSIGNED':
        return AppColors.warning;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'CLOSED':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeadDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchLeadDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _lead == null
          ? const Center(child: Text('Lead not found'))
          : RefreshIndicator(
              onRefresh: _fetchLeadDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSection('Customer Information', [
                      _buildInfoRow('Name', _lead!.customerName, Icons.person),
                      _buildInfoRow(
                        'Phone',
                        _lead!.contactPhone,
                        Icons.phone,
                        isPhone: true,
                      ),
                      _buildInfoRow(
                        'Email',
                        _lead!.email,
                        Icons.email,
                        isEmail: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Lead Details', [
                      _buildInfoRow(
                        'Requirement',
                        _lead!.requirementMessage,
                        Icons.description,
                      ),
                      _buildInfoRow('Source', _lead!.source, Icons.source),
                      _buildInfoRow(
                        'Status',
                        _lead!.status,
                        Icons.flag,
                        valueColor: _getStatusColor(_lead!.status),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Assignment Information', [
                      _buildInfoRow(
                        'Assigned To',
                        _lead!.assignedEmployeeName ?? 'Not Assigned',
                        Icons.assignment_ind,
                      ),
                      if (_lead!.assignedEmployeeMobile != null &&
                          _lead!.assignedEmployeeMobile!.isNotEmpty)
                        _buildInfoRow(
                          'Employee Mobile',
                          _lead!.assignedEmployeeMobile!,
                          Icons.phone_android,
                          isPhone: true,
                        ),
                      _buildInfoRow(
                        'Created By',
                        _lead!.createdByName ?? 'System',
                        Icons.person_add,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Dates', [
                      _buildInfoRow(
                        'Created',
                        _formatDate(_lead!.createdAt),
                        Icons.access_time,
                      ),
                      _buildInfoRow(
                        'Last Updated',
                        _formatDate(_lead!.updatedAt),
                        Icons.update,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Timeline Section
                    if (_lead!.timeline != null &&
                        _lead!.timeline!.isNotEmpty) ...[
                      _buildTimelineSection(),
                      const SizedBox(height: 24),
                    ],
                    // Calls Section
                    if (_lead!.calls != null && _lead!.calls!.isNotEmpty) ...[
                      _buildCallsSection(),
                      const SizedBox(height: 24),
                    ],
                    // Notes Section
                    if (_lead!.notes != null && _lead!.notes!.isNotEmpty) ...[
                      _buildNotesSection(),
                      const SizedBox(height: 24),
                    ],
                    // Follow-ups Section
                    if (_lead!.followUps != null &&
                        _lead!.followUps!.isNotEmpty) ...[
                      _buildFollowUpsSection(),
                      const SizedBox(height: 24),
                    ],
                    // Status History Section
                    if (_lead!.statusHistory != null &&
                        _lead!.statusHistory!.isNotEmpty) ...[
                      _buildStatusHistorySection(),
                      const SizedBox(height: 24),
                    ],
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(_lead!.status),
            _getStatusColor(_lead!.status).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_lead!.status).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lead!.customerName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lead!.contactPhone,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              _lead!.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isPhone) ..._buildPhoneActions(value),
          if (isEmail) _buildEmailAction(value),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneActions(String phone) {
    return [
      IconButton(
        onPressed: () => _makeCall(phone),
        icon: const Icon(Icons.call, color: AppColors.success),
        tooltip: 'Call',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: () => _openWhatsApp(phone),
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Color(0xFF25D366),
          size: 24,
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
      icon: const Icon(Icons.email, color: AppColors.primary),
      tooltip: 'Send Email',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
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

  Widget _buildActionButtons() {
    final isAssigned =
        _lead!.assignedEmployeeId != null &&
        _lead!.assignedEmployeeId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Remark button (full width)
        ElevatedButton.icon(
          onPressed: () => _navigateToRemark(),
          icon: const Icon(Icons.comment, size: 18),
          label: const Text('Add Remark'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isAssigned ? null : () => _showAssignDialog(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Update Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Expanded(
            //   child: OutlinedButton.icon(
            //     onPressed: isAssigned ? () => _showUnassignConfirm() : null,
            //     icon: const Icon(Icons.person_remove, size: 18),
            //     label: const Text('Unassign'),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: AppColors.warning,
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isAssigned ? () => _showUnassignConfirm() : null,
                icon: const Icon(Icons.person_remove, size: 18),
                label: const Text('Unassign'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Expanded(
            //   child: ElevatedButton.icon(
            //     onPressed: () => _showUpdateDialog(),
            //     icon: const Icon(Icons.edit, size: 18),
            //     label: const Text('Update Status'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.accent,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //     ),
            //   ),
            // ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirm(),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAssignDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectEmployeeScreen(
          leadId: widget.leadId,
          leadCustomerName: _lead!.customerName,
          assignedEmployeeId: _lead!.assignedEmployeeId,
          assignedEmployeeName: _lead!.assignedEmployeeName,
        ),
      ),
    ).then((_) => _fetchLeadDetails());
  }

  void _showUpdateDialog() {
    String selectedStatus = _lead!.status;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Status'),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
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
                  widget.leadId,
                  {'status': selectedStatus},
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully'),
                      ),
                    );
                    _fetchLeadDetails();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update status'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: const Text(
          'Are you sure you want to delete this lead? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().deleteLead(
                widget.leadId,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lead deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete lead'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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

  void _showUnassignConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Lead'),
        content: Text(
          'Are you sure you want to unassign this lead from ${_lead!.assignedEmployeeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().unassignLead(
                widget.leadId,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lead unassigned successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _fetchLeadDetails();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to unassign lead'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _lead!.timeline!.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getActionColor(event.action).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getActionIcon(event.action),
                        size: 20,
                        color: _getActionColor(event.action),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.action.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.details,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(event.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCallsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _lead!.calls!.map((call) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.call,
                        size: 20,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.action,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            call.details,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (call.actorName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'By: ${call.actorName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(call.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _lead!.notes!.map((note) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.note,
                        size: 20,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.details,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (note.actorName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'By: ${note.actorName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(note.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Follow-ups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _lead!.followUps!.map((followUp) {
              final Color statusColor;
              switch (followUp.status) {
                case 'COMPLETED':
                  statusColor = AppColors.success;
                  break;
                case 'CANCELLED':
                  statusColor = AppColors.error;
                  break;
                default:
                  statusColor = AppColors.warning;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              followUp.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (followUp.scheduledDateTime != null)
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Scheduled: ${_formatDate(followUp.scheduledDateTime!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (followUp.notes != null &&
                          followUp.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          followUp.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (followUp.employeeName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              followUp.employeeName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${_formatDate(followUp.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
    );
  }

  Widget _buildStatusHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _lead!.statusHistory!.map((history) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timeline,
                        size: 20,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    history.oldStatus,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  history.oldStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(history.oldStatus),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 14),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    history.newStatus,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  history.newStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(history.newStatus),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By: ${history.changedByName ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(history.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATED':
        return AppColors.success;
      case 'ASSIGNED':
        return AppColors.info;
      case 'UPDATED':
        return AppColors.warning;
      case 'DELETED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATED':
        return Icons.add_circle;
      case 'ASSIGNED':
        return Icons.assignment_ind;
      case 'UPDATED':
        return Icons.edit;
      case 'DELETED':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Future<void> _navigateToRemark() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRemarkScreen(
          leadId: widget.leadId,
          leadName: _lead!.customerName,
          phoneNumber: _lead!.contactPhone,
        ),
      ),
    );

    // Refresh lead details if remark was added successfully
    if (result == true) {
      _fetchLeadDetails();
    }
  }
}
