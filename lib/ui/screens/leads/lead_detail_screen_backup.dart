import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart' as call_log;
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/leads/lead_model.dart';
import 'package:crm_admin/data/models/leads/interaction_model.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/remark_provider.dart';
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
  int _selectedTabIndex = 0;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _callNotesController = TextEditingController();
  final TextEditingController _followUpNotesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Call log related
  bool _isCheckingPermission = false;
  bool _isSearchingCallLog = false;
  call_log.CallLogEntry? _foundCall;
  String? _permissionError;
  bool _callLogChecked = false;

  // Interaction fields
  String _selectedCallType = CallType.newLead;
  String _selectedFollowUpStatus = 'PENDING';
  DateTime? _selectedDateTime;

  final List<String> _tabs = ['Detail', 'Remark', 'Follow-ups', 'Actions', 'Timeline'];

  @override
  void initState() {
    super.initState();
    _fetchLeadDetails();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _callNotesController.dispose();
    _followUpNotesController.dispose();
    super.dispose();
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
                  : Column(
                      children: [
                        _buildFilterChips(),
                        Expanded(
                          child: _buildSelectedTabContent(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            _tabs.length,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedTabIndex == index,
                label: Text(_tabs[index]),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedTabIndex == index
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: _selectedTabIndex == index
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedTabIndex == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDetailsTab();
      case 1:
        return _buildRemarksTab();
      case 2:
        return _buildFollowUpsTab();
      case 3:
        return _buildActionsTab();
      case 4:
        return _buildTimelineTab();
      default:
        return _buildDetailsTab();
    }
  }

  Widget _buildDetailsTab() {
    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Customer Information
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
            
            // Lead Details
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
            
            // Assignment Information
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
            
            // Dates
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
              if (_lead!.nextFollowUp != null)
                _buildInfoRow(
                  'Next Follow-up',
                  _formatDate(_lead!.nextFollowUp),
                  Icons.event,
                  valueColor: AppColors.warning,
                ),
            ]),
            const SizedBox(height: 24),
            
            // Status History
            if (_lead!.statusHistory != null && _lead!.statusHistory!.isNotEmpty) ...[
              _buildExpandableSection(
                'Status History',
                Icons.history,
                _lead!.statusHistory!.length,
                _buildStatusHistoryList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Call Records
            if (_lead!.calls != null && _lead!.calls!.isNotEmpty) ...[
              _buildExpandableSection(
                'Call Records',
                Icons.call,
                _lead!.calls!.length,
                _buildCallRecordsList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Notes
            if (_lead!.notes != null && _lead!.notes!.isNotEmpty) ...[
              _buildExpandableSection(
                'Notes',
                Icons.note,
                _lead!.notes!.length,
                _buildNotesList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Follow-ups Summary
            if (_lead!.followUps != null && _lead!.followUps!.isNotEmpty) ...[
              _buildExpandableSection(
                'Follow-ups',
                Icons.schedule,
                _lead!.followUps!.length,
                _buildFollowUpsSummary(),
              ),
              const SizedBox(height: 24),
            ],
            
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    IconData icon,
    int count,
    Widget content,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryList() {
    return Column(
      children: _lead!.statusHistory!.map((history) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(history.oldStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      history.oldStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(history.oldStatus),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(history.newStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      history.newStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(history.newStatus),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    history.changedByName ?? 'System',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(history.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCallRecordsList() {
    return Column(
      children: _lead!.calls!.map((call) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.call, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      call.action.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                call.details,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (call.actorName != null) ...[
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      call.actorName!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(call.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesList() {
    return Column(
      children: _lead!.notes!.map((note) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.note, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.action.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.details,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (note.actorName != null) ...[
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      note.actorName!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFollowUpsSummary() {
    return Column(
      children: _lead!.followUps!.map((followUp) {
        final isPending = followUp.status == 'PENDING';
        final isCompleted = followUp.status == 'COMPLETED';
        final isCancelled = followUp.status == 'CANCELLED';

        Color statusColor = isPending
            ? AppColors.warning
            : isCompleted
                ? AppColors.success
                : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      followUp.status ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (followUp.scheduledDateTime != null)
                    Expanded(
                      child: Text(
                        _formatDate(followUp.scheduledDateTime!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  followUp.notes!,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemarksTab() {
    return Column(
      children: [
        // Add Interaction Form Section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lead info card
                  if (_lead != null) ...[
                    Card(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.business, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _lead!.customerName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _lead!.contactPhone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Call Type Dropdown
                  const Text(
                    'Call Type *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCallType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: CallType.all.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(CallType.getDisplayName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCallType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Call log search button
                  ElevatedButton.icon(
                    onPressed: _isSearchingCallLog ? null : _searchCallLog,
                    icon: _isSearchingCallLog
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      _isSearchingCallLog ? 'Searching...' : 'Search Call Log',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (_permissionError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _permissionError!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_foundCall != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Call Found',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type: ${_foundCall!.callType.toString().split('.').last.toUpperCase()}',
                          ),
                          Text('Duration: ${(_foundCall!.duration ?? 0)} seconds'),
                          Text(
                            'Time: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_foundCall!.timestamp!))}',
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_callLogChecked && _foundCall == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No recent calls found. You can still add interaction manually.',
                              style: TextStyle(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Call Notes field
                  const Text(
                    'Call Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _callNotesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter details about the call...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Follow-up fields (conditional on call type)
                  if (_selectedCallType == CallType.followUpScheduled || 
                      _selectedCallType == CallType.callbackRequested) ...[
                    const Text(
                      'Follow-up Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Follow-up status
                    DropdownButtonFormField<String>(
                      value: _selectedFollowUpStatus,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFollowUpStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Follow-up notes
                    TextFormField(
                      controller: _followUpNotesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        hintText: 'e.g., Schedule demo call, Discuss pricing...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scheduled date/time picker
                    ElevatedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDateTime == null
                            ? 'Select Date & Time *'
                            : DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(_selectedDateTime!),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedDateTime == null
                            ? AppColors.warning
                            : AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  Consumer<RemarkProvider>(
                    builder: (context, provider, _) {
                      final isEnabled = !provider.isLoading && _canSubmit;
                      return ElevatedButton(
                        onPressed: isEnabled ? _submitInteraction : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Submit Interaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Divider(),
                  const SizedBox(height: 16),

                  // Notes history header
                  const Text(
                    'Interaction History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes list
                  if (_lead!.notes == null || _lead!.notes!.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No interaction history yet',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lead!.notes!.length,
                    itemBuilder: (context, index) {
                      final note = _lead!.notes![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                    child: Text(
                                      note.action,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                note.details,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (note.actorName != null) ...[
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
                                      'By: ${note.actorName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(note.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Check if submit button should be enabled
  bool get _canSubmit {
    if (_foundCall == null) return false;
    final hasContent = _callNotesController.text.trim().isNotEmpty;
    if (_selectedCallType == CallType.followUpScheduled ||
        _selectedCallType == CallType.callbackRequested) {
      return hasContent && _selectedDateTime != null;
    }
    return hasContent;
  }

  // Check and request call log permission
  Future<bool> _checkAndRequestPermission() async {
    setState(() {
      _isCheckingPermission = true;
      _permissionError = null;
    });

    try {
      dev.log('🔐 Checking call log permission');
      final status = await Permission.phone.status;

      if (status.isGranted) {
        dev.log('✅ Permission already granted');
        setState(() {
          _isCheckingPermission = false;
        });
        return true;
      } else if (status.isDenied) {
        dev.log('⚠️ Permission denied, requesting...');
        final result = await Permission.phone.request();

        if (result.isGranted) {
          dev.log('✅ Permission granted after request');
          setState(() {
            _isCheckingPermission = false;
          });
          return true;
        } else {
          dev.log('❌ Permission denied by user');
          setState(() {
            _isCheckingPermission = false;
            _permissionError =
                'Call log permission is required to log calls automatically';
          });
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        dev.log('❌ Permission permanently denied');
        setState(() {
          _isCheckingPermission = false;
          _permissionError =
              'Permission denied. Please enable in app settings.';
        });
        return false;
      }

      setState(() {
        _isCheckingPermission = false;
      });
      return false;
    } catch (e) {
      dev.log('❌ Error checking permission: $e');
      setState(() {
        _isCheckingPermission = false;
        _permissionError = 'Error checking permissions';
      });
      return false;
    }
  }

  // Search for most recent call with this number
  Future<void> _searchCallLog() async {
    if (_lead == null) return;
    
    if (!await _checkAndRequestPermission()) {
      return;
    }

    setState(() {
      _isSearchingCallLog = true;
      _foundCall = null;
      _callLogChecked = true;
    });

    try {
      dev.log('🔍 Searching call log for number: ${_lead!.contactPhone}');

      final Iterable<call_log.CallLogEntry> entries =
          await call_log.CallLog.query(
            number: _lead!.contactPhone,
            dateFrom: DateTime.now()
                .subtract(const Duration(days: 7))
                .millisecondsSinceEpoch,
            dateTo: DateTime.now().millisecondsSinceEpoch,
          );

      if (entries.isNotEmpty) {
        final mostRecent = entries.first;
        dev.log(
          '✅ Found call: ${mostRecent.callType}, duration: ${mostRecent.duration}s',
        );

        setState(() {
          _foundCall = mostRecent;
          _isSearchingCallLog = false;
        });
      } else {
        dev.log('⚠️ No calls found in last 7 days');
        setState(() {
          _isSearchingCallLog = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recent calls found in last 7 days'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('❌ Error searching call log: $e');
      setState(() {
        _isSearchingCallLog = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching call log: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Show datetime picker for follow-up scheduling
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // Submit the interaction
  Future<void> _submitInteraction() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_canSubmit) {
      String message;
      if (_foundCall == null) {
        message = 'Please search and find a call in call logs first';
      } else if ((_selectedCallType == CallType.followUpScheduled ||
              _selectedCallType == CallType.callbackRequested) &&
          _selectedDateTime == null) {
        message = 'Please provide call notes and schedule date/time';
      } else {
        message = 'Please provide call notes';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.warning),
      );
      return;
    }

    final provider = context.read<RemarkProvider>();
    provider.clearMessages();

    // Build interaction request
    final request = LeadInteractionRequest(
      callType: _selectedCallType,
      remark: null,
      callNotes: _callNotesController.text.trim().isNotEmpty
          ? _callNotesController.text.trim()
          : null,
      callDuration: _foundCall?.duration,
      followUpStatus: (_selectedCallType == CallType.followUpScheduled ||
              _selectedCallType == CallType.callbackRequested)
          ? _selectedFollowUpStatus
          : null,
      followUpNotes: _followUpNotesController.text.trim().isNotEmpty
          ? _followUpNotesController.text.trim()
          : null,
      scheduledDateTime: _selectedDateTime != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_selectedDateTime!)
          : null,
    );

    dev.log('📝 Submitting interaction');
    final success = await provider.recordInteraction(
      leadId: widget.leadId,
      request: request,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to record interaction'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show success and refresh
    if (mounted) {
      _callNotesController.clear();
      _followUpNotesController.clear();
      setState(() {
        _foundCall = null;
        _callLogChecked = false;
        _selectedDateTime = null;
        _selectedCallType = CallType.newLead;
        _selectedFollowUpStatus = 'PENDING';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interaction recorded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _fetchLeadDetails();
    }
  }

  Widget _buildFollowUpsTab() {
    if (_lead?.followUps == null || _lead!.followUps!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No follow-ups scheduled',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    
    // Categorize follow-ups
    final missedFollowUps = _lead!.followUps!.where((followUp) {
      if (followUp.status == 'COMPLETED' || followUp.status == 'CANCELLED') {
        return false;
      }
      if (followUp.scheduledDateTime != null) {
        try {
          final scheduledTime = DateTime.parse(followUp.scheduledDateTime!);
          return scheduledTime.isBefore(now);
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();

    final upcomingFollowUps = _lead!.followUps!.where((followUp) {
      if (followUp.status == 'COMPLETED' || followUp.status == 'CANCELLED') {
        return false;
      }
      if (followUp.scheduledDateTime != null) {
        try {
          final scheduledTime = DateTime.parse(followUp.scheduledDateTime!);
          return scheduledTime.isAfter(now);
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();

    final completedFollowUps = _lead!.followUps!.where((followUp) {
      return followUp.status == 'COMPLETED';
    }).toList();

    final cancelledFollowUps = _lead!.followUps!.where((followUp) {
      return followUp.status == 'CANCELLED';
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next Follow-up Section
            if (_lead?.nextFollowUp != null) ...[
              Text(
                'Next Follow-up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppColors.info.withOpacity(0.1),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.info, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _lead!.nextFollowUp!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Missed Follow-ups Warning
            if (missedFollowUps.isNotEmpty) ...[
              Text(
                'Missed Follow-ups ⚠️',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 12),
              ...missedFollowUps.map((followUp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.error.withOpacity(0.1),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.error, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MISSED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                                if (followUp.scheduledDateTime != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(
                                      DateTime.parse(followUp.scheduledDateTime!),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          followUp.notes!,
                          style: const TextStyle(fontSize: 14),
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
                              'Assigned: ${followUp.employeeName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Upcoming Follow-ups
            if (upcomingFollowUps.isNotEmpty) ...[
              Text(
                'Upcoming Follow-ups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...upcomingFollowUps.map((followUp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  followUp.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                if (followUp.scheduledDateTime != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(
                                      DateTime.parse(followUp.scheduledDateTime!),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          followUp.notes!,
                          style: const TextStyle(fontSize: 14),
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
                              'Assigned: ${followUp.employeeName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Completed Follow-ups
            if (completedFollowUps.isNotEmpty) ...[
              Text(
                'Completed Follow-ups ✓',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 12),
              ...completedFollowUps.map((followUp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.success.withOpacity(0.05),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                if (followUp.scheduledDateTime != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(
                                      DateTime.parse(followUp.scheduledDateTime!),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          followUp.notes!,
                          style: const TextStyle(fontSize: 14),
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
                              'Completed by: ${followUp.employeeName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Cancelled Follow-ups
            if (cancelledFollowUps.isNotEmpty) ...[
              Text(
                'Cancelled Follow-ups ✕',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ...cancelledFollowUps.map((followUp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.grey.withOpacity(0.05),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CANCELLED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (followUp.scheduledDateTime != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(
                                      DateTime.parse(followUp.scheduledDateTime!),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          followUp.notes!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                      if (followUp.employeeName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cancelled by: ${followUp.employeeName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // All Remarks Section
            Text(
              'All Remarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_lead!.notes == null || _lead!.notes!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No remarks available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_lead!.notes!.map((note) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                            child: Text(
                              note.action,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note.details,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (note.actorName != null) ...[
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
                              'By: ${note.actorName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ))),

            // Empty state if no data at all
            if ((_lead!.followUps == null || _lead!.followUps!.isEmpty) &&
                (_lead!.notes == null || _lead!.notes!.isEmpty) &&
                _lead!.nextFollowUp == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No follow-ups or remarks yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Remark Action
          _buildActionCard(
            icon: Icons.note_add_rounded,
            title: 'Add Remark',
            description: 'Add notes, comments or observations about this lead',
            color: AppColors.info,
            onTap: () => _navigateToRemark(),
          ),
          const SizedBox(height: 12),
          
          // Assign/Unassign Action
          _buildActionCard(
            icon: _lead!.assignedEmployeeId != null 
                ? Icons.person_remove_rounded 
                : Icons.person_add_rounded,
            title: _lead!.assignedEmployeeId != null 
                ? 'Unassign Lead' 
                : 'Assign Lead',
            description: _lead!.assignedEmployeeId != null
                ? 'Remove assignment from ${_lead!.assignedEmployeeName ?? "employee"}'
                : 'Assign this lead to an employee',
            color: _lead!.assignedEmployeeId != null 
                ? AppColors.warning 
                : AppColors.success,
            onTap: () {
              if (_lead!.assignedEmployeeId != null) {
                _showUnassignDialog();
              } else {
                _navigateToAssignEmployee();
              }
            },
          ),
          const SizedBox(height: 12),
          
          // Update Status Action
          _buildActionCard(
            icon: Icons.edit_rounded,
            title: 'Update Status',
            description: 'Change the current status of this lead',
            color: AppColors.primary,
            onTap: () => _showUpdateDialog(),
          ),
          const SizedBox(height: 12),
          
          // Delete Action
          _buildActionCard(
            icon: Icons.delete_rounded,
            title: 'Delete Lead',
            description: 'Permanently remove this lead from the system',
            color: AppColors.error,
            onTap: () => _showDeleteDialog(),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Contact Actions Section
          Text(
            'Quick Contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: AppColors.success,
                  onTap: () => _makePhoneCall(_lead!.contactPhone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: AppColors.info,
                  onTap: () => _sendEmail(_lead!.email),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: Color(0xFF25D366),
                  onTap: () => _openWhatsApp(_lead!.contactPhone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_lead!.timeline == null || _lead!.timeline!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No timeline activity',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _lead!.timeline!.length,
        itemBuilder: (context, index) {
          final event = _lead!.timeline![index];
          final isLast = index == _lead!.timeline!.length - 1;
          
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator column
                Column(
                  children: [
                    // Circle indicator
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getActionColor(event.action),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getActionColor(event.action).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getActionIcon(event.action),
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    // Connecting line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getActionColor(event.action),
                                Colors.grey.shade300,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getActionColor(event.action).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.action.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _getActionColor(event.action),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getActionColor(event.action).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimeAgo(event.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getActionColor(event.action),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.details,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        if (event.actorName != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.actorName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(event.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
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
        icon: const Icon(Icons.call, color: AppColors.success, size: 22),
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
          size: 22,
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
      icon: const Icon(Icons.email, color: AppColors.primary, size: 22),
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
          SnackBar(content: Text('Could not make call: $phone')),
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
          label: const Text('Add Remark / Log Call'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirm(),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Text('Update Status'),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'NEW', child: Text('New')),
              DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
              DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
              DropdownMenuItem(value: 'QUALIFIED', child: Text('Qualified')),
              DropdownMenuItem(value: 'FOLLOW_UP_SCHEDULED', child: Text('Follow-up Scheduled')),
              DropdownMenuItem(value: 'CALLBACK_REQUESTED', child: Text('Callback Requested')),
              DropdownMenuItem(value: 'NO_RESPONSE', child: Text('No Response')),
              DropdownMenuItem(value: 'DISQUALIFIED', child: Text('Disqualified')),
              DropdownMenuItem(value: 'CONVERTING', child: Text('Converting')),
              DropdownMenuItem(value: 'CONVERTED', child: Text('Converted')),
              DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
            ],
            onChanged: (v) => setState(() => selectedStatus = v!),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<LeadsProvider>().updateLead(
                      widget.leadId,
                      {'status': selectedStatus},
                    );
                if (mounted) {
                  Navigator.pop(dialogContext);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully'),
                        backgroundColor: AppColors.success,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Text('Delete Lead'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this lead? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().deleteLead(
                    widget.leadId,
                  );
              if (mounted) {
                Navigator.pop(dialogContext);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lead deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUnassignConfirm() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Text('Unassign Lead'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to unassign this lead from ${_lead!.assignedEmployeeName}?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().unassignLead(
                    widget.leadId,
                  );
              if (mounted) {
                Navigator.pop(dialogContext);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unassign'),
          ),
        ],
      ),
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

  Future<void> _navigateToAssignEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectEmployeeScreen(
          leadId: widget.leadId,
          leadCustomerName: _lead!.customerName,
        ),
      ),
    );

    // Refresh lead details if assignment was successful
    if (result == true) {
      _fetchLeadDetails();
    }
  }

  void _showUnassignDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Text('Unassign Lead'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to unassign this lead from ${_lead!.assignedEmployeeName ?? "the employee"}?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().unassignLead(
                    widget.leadId,
                  );
              if (mounted) {
                Navigator.pop(dialogContext);
                if (success) {
                  _fetchLeadDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lead unassigned successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Text('Delete Lead'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this lead? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<LeadsProvider>().deleteLead(
                    widget.leadId,
                  );
              if (mounted) {
                Navigator.pop(dialogContext);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lead deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make phone call')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address available')),
      );
      return;
    }
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send email')),
        );
      }
    }
  }

}
