import 'dart:developer' as dev;
import 'dart:io';
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
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/ui/screens/leads/select_employee_screen.dart';
import 'package:crm_admin/ui/screens/leads/add_remark_screen.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  LeadModel? _lead;
  late TabController _tabController;

  // Status filter for follow-ups tab
  String? _selectedFollowUpStatus;

  // Add Interaction form state
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _callNotesController = TextEditingController();
  final _followUpNotesController = TextEditingController();
  bool _isCheckingPermission = false;
  bool _isSearchingCallLog = false;
  call_log.CallLogEntry? _foundCall;
  String? _permissionError;
  bool _callLogChecked = false;
  String _selectedCallType = CallType.newLead;
  String _selectedFollowUpStatus2 = 'PENDING';
  DateTime? _selectedDateTime;

  // Samsung device detection
  bool get _isSamsungDevice {
    if (Platform.isAndroid) {
      // Check if manufacturer contains Samsung
      return true; // Will check manufacturer at runtime
    }
    return false;
  }

  double get _extraBottomPadding {
    // Add extra 40px padding for Samsung devices with gesture navigation
    return _isSamsungDevice ? 40.0 : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchLeadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'FOLLOW_UP_SCHEDULED':
        return Colors.teal;
      case 'CALLBACK_REQUESTED':
        return Colors.amber;
      case 'NO_RESPONSE':
        return Colors.grey;
      case 'COMPLETED':
        return Colors.green;
      case 'CLOSED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  Color _getFollowUpStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'MISSED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showReassignDialog() {
    print('🔄 [LeadDetail] Opening reassign dialog');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectEmployeeScreen(
          leadId: widget.leadId,
          leadCustomerName: _lead?.customerName ?? 'Lead',
          assignedEmployeeId: _lead?.assignedEmployeeId,
          assignedEmployeeName: _lead?.assignedEmployeeName,
        ),
      ),
    ).then((reassigned) {
      if (reassigned == true) {
        print('✅ [LeadDetail] Lead reassigned, refreshing details');
        _fetchLeadDetails();
      }
    });
  }

  Future<void> _showTransferBottomSheet() async {
    print('🔄 [LeadDetail] Opening transfer bottom sheet');
    print('   Current Lead ID: ${widget.leadId}');
    print(
      '   Current Employee: ${_lead?.assignedEmployeeName} (${_lead?.assignedEmployeeId})',
    );

    // Fetch employees first
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();

    if (!mounted) return;

    final employees = userProvider.users
        .where(
          (u) =>
              u.role == 'EMPLOYEE' &&
              u.isActive &&
              u.id != _lead?.assignedEmployeeId,
        )
        .toList();

    print(
      '📋 [LeadDetail] Found ${employees.length} available employees for transfer',
    );

    if (employees.isEmpty) {
      print('⚠️ [LeadDetail] No employees available for transfer');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other employees available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transfer Lead',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select employee to transfer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        print('❌ [LeadDetail] Transfer cancelled');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Employee List
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 +
                        MediaQuery.of(context).viewPadding.bottom +
                        _extraBottomPadding,
                  ),
                  itemCount: employees.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          employee.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      title: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        employee.username,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () async {
                        print(
                          '✅ [LeadDetail] Employee selected: ${employee.fullName} (${employee.id})',
                        );

                        // Save navigator and scaffold messenger BEFORE closing bottom sheet
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        // Close bottom sheet
                        navigator.pop();

                        // Show loading dialog
                        showDialog(
                          context: navigator.context,
                          barrierDismissible: false,
                          builder: (ctx) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        print(
                          '🔄 [LeadDetail] Initiating transfer to employee ID: ${employee.id}',
                        );

                        // Get provider before any navigation changes
                        final leadsProvider = Provider.of<LeadsProvider>(
                          navigator.context,
                          listen: false,
                        );
                        final success = await leadsProvider.transferLead(
                          widget.leadId,
                          employee.id,
                        );

                        // Close loading dialog safely
                        navigator.pop();

                        // Show result
                        if (success) {
                          print(
                            '✅ [LeadDetail] Transfer successful, refreshing details',
                          );
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Lead transferred to ${employee.fullName}',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (mounted) {
                            await _fetchLeadDetails();
                          }
                        } else {
                          print(
                            '❌ [LeadDetail] Transfer failed: ${leadsProvider.error}',
                          );
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Transfer failed: ${leadsProvider.error}',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignBottomSheet() async {
    print('🔄 [LeadDetail] Opening assign bottom sheet');
    print('   Lead ID: ${widget.leadId}');

    // Fetch employees
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();

    if (!mounted) return;

    final employees = userProvider.users
        .where((u) => u.role == 'EMPLOYEE' && u.isActive)
        .toList();

    print(
      '📋 [LeadDetail] Found ${employees.length} available employees for assignment',
    );

    if (employees.isEmpty) {
      print('⚠️ [LeadDetail] No employees available for assignment');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No employees available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.withOpacity(0.8), Colors.green],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Lead',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select employee to assign',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        print('❌ [LeadDetail] Assign cancelled');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Employee List
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 +
                        MediaQuery.of(context).viewPadding.bottom +
                        _extraBottomPadding,
                  ),
                  itemCount: employees.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green.withOpacity(0.2),
                        child: Text(
                          employee.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      title: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        employee.username,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () async {
                        print(
                          '✅ [LeadDetail] Employee selected: ${employee.fullName} (${employee.id})',
                        );

                        // Save references before navigation
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        // Close bottom sheet
                        navigator.pop();

                        // Show loading
                        showDialog(
                          context: navigator.context,
                          barrierDismissible: false,
                          builder: (ctx) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        print(
                          '🔄 [LeadDetail] Initiating assignment to employee ID: ${employee.id}',
                        );
                        final leadsProvider = Provider.of<LeadsProvider>(
                          navigator.context,
                          listen: false,
                        );
                        final success = await leadsProvider.assignLead(
                          widget.leadId,
                          employee.id,
                        );

                        // Close loading
                        navigator.pop();

                        if (success) {
                          print(
                            '✅ [LeadDetail] Assignment successful, refreshing details',
                          );
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Lead assigned to ${employee.fullName}',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (mounted) {
                            await _fetchLeadDetails();
                          }
                        } else {
                          print(
                            '❌ [LeadDetail] Assignment failed: ${leadsProvider.error}',
                          );
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Assignment failed: ${leadsProvider.error}',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnassignConfirmDialog() {
    print('🔄 [LeadDetail] Opening unassign confirmation dialog');
    print('   Lead ID: ${widget.leadId}');
    print(
      '   Current Employee: ${_lead?.assignedEmployeeName} (${_lead?.assignedEmployeeId})',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unassign Lead'),
          ],
        ),
        content: Text(
          'Are you sure you want to unassign this lead from ${_lead?.assignedEmployeeName ?? "the employee"}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [LeadDetail] Unassign cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print('🔄 [LeadDetail] Unassign confirmed');

              // Save references before any navigation
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Close confirmation dialog
              navigator.pop();

              // Show loading
              showDialog(
                context: navigator.context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final leadsProvider = Provider.of<LeadsProvider>(
                navigator.context,
                listen: false,
              );
              final success = await leadsProvider.unassignLead(widget.leadId);

              // Close loading
              navigator.pop();

              if (success) {
                print('✅ [LeadDetail] Unassign successful, refreshing details');
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Lead unassigned successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (mounted) {
                  await _fetchLeadDetails();
                }
              } else {
                print('❌ [LeadDetail] Unassign failed: ${leadsProvider.error}');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to unassign: ${leadsProvider.error}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    print('🔄 [LeadDetail] Opening delete confirmation dialog');
    print('   Lead ID: ${widget.leadId}');
    print('   Customer Name: ${_lead?.customerName}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Lead'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the lead for "${_lead?.customerName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [LeadDetail] Delete cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print('🔄 [LeadDetail] Delete confirmed');

              // Save references before any navigation
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Close confirmation dialog
              navigator.pop();

              // Show loading
              showDialog(
                context: navigator.context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final leadsProvider = Provider.of<LeadsProvider>(
                navigator.context,
                listen: false,
              );
              final success = await leadsProvider.deleteLead(widget.leadId);

              // Close loading
              navigator.pop();

              if (success) {
                print(
                  '✅ [LeadDetail] Delete successful, navigating back to leads list',
                );
                // Go back to leads list (pop current screen) with result
                navigator.pop(true);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Lead deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                print('❌ [LeadDetail] Delete failed: ${leadsProvider.error}');

                // Check if error is about foreign key constraint
                String errorMessage = 'Failed to delete lead';
                if (leadsProvider.error?.contains('foreign key constraint') ==
                        true ||
                    leadsProvider.error?.contains('follow_ups') == true ||
                    leadsProvider.error?.contains('still referenced') == true) {
                  errorMessage =
                      'Cannot delete: Lead has associated follow-ups. Please contact support.';
                } else if (leadsProvider.error != null) {
                  errorMessage = 'Failed to delete: ${leadsProvider.error}';
                }

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRemarkDialog() {
    setState(() {
      _showAddForm = !_showAddForm;
      if (_showAddForm && !_callLogChecked) {
        // Auto search call log when opening form
        Future.delayed(Duration.zero, _searchCallLog);
      }
    });
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
      followUpStatus:
          (_selectedCallType == CallType.followUpScheduled ||
              _selectedCallType == CallType.callbackRequested)
          ? _selectedFollowUpStatus2
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
        _selectedFollowUpStatus2 = 'PENDING';
        _showAddForm = false;
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

  Future<void> _updateLeadStatus(String newStatus) async {
    try {
      final apiClient = ApiClient();
      await apiClient.put(
        ApiEndpoints.updateLead(widget.leadId),
        data: {'status': newStatus},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchLeadDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.accent.withOpacity(0.9),
                  AppColors.accent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            _lead?.customerName ?? 'Lead Details',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchLeadDetails,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Detail'),
              Tab(icon: Icon(Icons.comment, size: 20), text: 'Remarks'),
              Tab(icon: Icon(Icons.event, size: 20), text: 'Follow-ups'),
              Tab(icon: Icon(Icons.touch_app, size: 20), text: 'Actions'),
              Tab(icon: Icon(Icons.timeline, size: 20), text: 'Timeline'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchLeadDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailTab(),
                  _buildRemarksTab(),
                  _buildFollowUpsTab(),
                  _buildActionsTab(),
                  _buildTimelineTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailTab() {
    if (_lead == null) return const Center(child: Text('No lead data'));

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
          bottom: 10 + _extraBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lead Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _lead!.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_lead!.status),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _lead!.status.replaceAll('_', ' '),
                            style: TextStyle(
                              color: _getStatusColor(_lead!.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.person,
                      'Customer Name',
                      _lead!.customerName,
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      _lead!.contactPhone,
                      onTap: () => _makePhoneCall(_lead!.contactPhone),
                    ),
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      _lead!.email.isNotEmpty ? _lead!.email : 'N/A',
                      onTap: _lead!.email.isNotEmpty
                          ? () => _sendEmail(_lead!.email)
                          : null,
                    ),
                    _buildInfoRow(Icons.source, 'Source', _lead!.source),
                    _buildInfoRow(
                      Icons.message,
                      'Requirement',
                      _lead!.requirementMessage,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Created At',
                      _formatDate(_lead!.createdAt),
                    ),
                    _buildInfoRow(
                      Icons.update,
                      'Last Updated',
                      _formatDate(_lead!.updatedAt),
                    ),
                    if (_lead!.nextFollowUp != null &&
                        _lead!.nextFollowUp!['scheduledDateTime'] != null)
                      _buildInfoRow(
                        Icons.schedule,
                        'Next Follow-up',
                        _formatDate(_lead!.nextFollowUp!['scheduledDateTime']),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Employee Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Employee',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    if (_lead!.assignedEmployeeName != null) ...[
                      _buildInfoRow(
                        Icons.person_outline,
                        'Employee',
                        _lead!.assignedEmployeeName!,
                      ),
                      if (_lead!.assignedEmployeeMobile != null)
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Mobile',
                          _lead!.assignedEmployeeMobile!,
                          onTap: () =>
                              _makePhoneCall(_lead!.assignedEmployeeMobile!),
                        ),
                    ] else
                      const Text(
                        'Not assigned yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Created By Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lead Created By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.person_add,
                      'Created By',
                      _lead!.createdByName ?? _lead!.createdBy,
                    ),
                  ],
                ),
              ),
            ),
            // Extra padding for Samsung devices with gesture navigation
            SizedBox(height: _extraBottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksTab() {
    final notes = _lead?.notes ?? [];

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.info, AppColors.info.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.comment_bank,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Remarks & Interactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: _showAddRemarkDialog,
                    icon: Icon(
                      _showAddForm ? Icons.close : Icons.add_circle,
                      size: 20,
                    ),
                    label: Text(_showAddForm ? 'Close Form' : 'Add Remark'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showAddForm
                          ? AppColors.warning
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expandable Add Form
          if (_showAddForm) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lead info card
                      Card(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.business,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _lead?.customerName ?? '',
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
                                    _lead?.contactPhone ?? '',
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
                      const SizedBox(height: 24),

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
                      const SizedBox(height: 24),

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
                          _isSearchingCallLog
                              ? 'Searching...'
                              : 'Search Call Log',
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
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _permissionError!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
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
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
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
                              Text(
                                'Duration: ${(_foundCall!.duration ?? 0)} seconds',
                              ),
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
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                              ),
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

                      const SizedBox(height: 24),

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
                      const SizedBox(height: 24),

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
                          value: _selectedFollowUpStatus2,
                          decoration: InputDecoration(
                            labelText: 'Follow-up Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PENDING',
                              child: Text('Pending'),
                            ),
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
                              _selectedFollowUpStatus2 = value!;
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
                            hintText:
                                'e.g., Schedule demo call, Discuss pricing...',
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
                        const SizedBox(height: 24),
                      ],

                      // Submit button
                      Consumer<RemarkProvider>(
                        builder: (context, provider, _) {
                          final isEnabled =
                              !provider.isLoading && _foundCall != null;
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
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Remarks List
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.info.withOpacity(0.1),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.note_outlined,
                              size: 60,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No remarks yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first remark to this lead',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 +
                            MediaQuery.of(context).viewPadding.bottom +
                            _extraBottomPadding,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final colors = [
                          [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                          [AppColors.info, AppColors.info.withOpacity(0.7)],
                          [
                            AppColors.success,
                            AppColors.success.withOpacity(0.7),
                          ],
                          [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                        ];
                        final colorPair = colors[index % colors.length];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  colorPair[0].withOpacity(0.05),
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: colorPair[0].withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: colorPair,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note.actorName ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(note.timestamp),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      note.details,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildFollowUpsTab() {
    var followUps = _lead?.followUps ?? [];

    // Apply status filter
    if (_selectedFollowUpStatus != null) {
      followUps = followUps
          .where((f) => f.status == _selectedFollowUpStatus)
          .toList();
    }

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   'Follow-ups',
                //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 10),
                Wrap(
                  spacing: 3,
                  runSpacing: 0,
                  children: [
                    _buildFilterChip('All', null),
                    _buildFilterChip('Pending', 'PENDING'),
                    _buildFilterChip('Completed', 'COMPLETED'),
                    _buildFilterChip('Missed', 'MISSED'),
                    _buildFilterChip('Cancelled', 'CANCELLED'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: followUps.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No follow-ups found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(context).viewPadding.bottom +
                          12 +
                          _extraBottomPadding,
                    ),
                    itemCount: followUps.length,
                    itemBuilder: (context, index) {
                      final followUp = followUps[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getFollowUpStatusColor(
                              followUp.status,
                            ).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getFollowUpStatusColor(
                                        followUp.status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      followUp.status,
                                      style: TextStyle(
                                        color: _getFollowUpStatusColor(
                                          followUp.status,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDateShort(
                                      followUp.scheduledDateTime,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    followUp.employeeName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (followUp.notes != null &&
                                  followUp.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  followUp.notes!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedFollowUpStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFollowUpStatus = selected ? status : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + _extraBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.phone,
            title: 'Make Call',
            subtitle: 'Call the customer',
            color: Colors.green,
            onTap: () => _makePhoneCall(_lead!.contactPhone),
          ),
          _buildActionCard(
            icon: Icons.email,
            title: 'Send Email',
            subtitle: 'Send email to customer',
            color: Colors.blue,
            onTap: _lead!.email.isNotEmpty
                ? () => _sendEmail(_lead!.email)
                : null,
          ),
          // _buildActionCard(
          //   icon: Icons.assignment_ind,
          //   title: 'Reassign Lead',
          //   subtitle: 'Assign to another employee',
          //   color: Colors.orange,
          //   onTap: _showReassignDialog,
          // ),
          _buildActionCard(
            icon: Icons.swap_horiz,
            title: 'Transfer Lead',
            subtitle: 'Transfer to another employee',
            color: Colors.teal,
            onTap: _showTransferBottomSheet,
          ),
          if (_lead!.assignedEmployeeId == null ||
              _lead!.assignedEmployeeId!.isEmpty)
            _buildActionCard(
              icon: Icons.person_add,
              title: 'Assign Lead',
              subtitle: 'Assign to an employee',
              color: Colors.green,
              onTap: _showAssignBottomSheet,
            )
          else
            _buildActionCard(
              icon: Icons.person_remove,
              title: 'Unassign Lead',
              subtitle: 'Remove from ${_lead!.assignedEmployeeName}',
              color: Colors.orange.shade700,
              onTap: _showUnassignConfirmDialog,
            ),
          _buildActionCard(
            icon: Icons.note_add,
            title: 'Add Remark',
            subtitle: 'Add a new remark',
            color: Colors.purple,
            onTap: _showAddRemarkDialog,
          ),
          _buildActionCard(
            icon: Icons.delete_forever,
            title: 'Delete Lead',
            subtitle: 'Permanently delete this lead',
            color: Colors.red,
            onTap: _showDeleteConfirmDialog,
          ),
          const SizedBox(height: 20),
          const Text(
            'Update Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 2,
            runSpacing: 6,
            children: [
              _buildStatusChip('IN_PROGRESS'),
              _buildStatusChip('FOLLOW_UP_SCHEDULED'),
              _buildStatusChip('CALLBACK_REQUESTED'),
              _buildStatusChip('NO_RESPONSE'),
              _buildStatusChip('COMPLETED'),
              _buildStatusChip('CLOSED'),
              _buildStatusChip('CANCELLED'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final currentStatus = _lead?.status ?? '';
    final isCurrentStatus = currentStatus == status;
    final statusColor = _getStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrentStatus ? null : () => _updateLeadStatus(status),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentStatus ? statusColor : statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: isCurrentStatus ? Colors.white : statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    final timeline = _lead?.timeline ?? [];

    return RefreshIndicator(
      onRefresh: _fetchLeadDetails,
      color: AppColors.primary,
      child: timeline.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                10,
                14,
                10,
                14 +
                    MediaQuery.of(context).viewPadding.bottom +
                    _extraBottomPadding,
              ),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final event = timeline[index];
                final isLast = index == timeline.length - 1;

                // Determine event color based on action type
                Color eventColor;
                IconData eventIcon;
                switch (event.action.toUpperCase()) {
                  case 'CREATED':
                  case 'CREATE':
                    eventColor = AppColors.success;
                    eventIcon = Icons.add_circle_outline;
                    break;
                  case 'UPDATED':
                  case 'UPDATE':
                  case 'MODIFIED':
                    eventColor = AppColors.warning;
                    eventIcon = Icons.edit_outlined;
                    break;
                  case 'ASSIGNED':
                  case 'REASSIGNED':
                    eventColor = AppColors.info;
                    eventIcon = Icons.person_outline;
                    break;
                  case 'DELETED':
                  case 'DELETE':
                    eventColor = AppColors.error;
                    eventIcon = Icons.delete_outline;
                    break;
                  case 'REMARK':
                  case 'COMMENT':
                  case 'NOTE':
                    eventColor = Colors.purple;
                    eventIcon = Icons.comment_outlined;
                    break;
                  case 'CALL':
                  case 'CALLED':
                    eventColor = Colors.green;
                    eventIcon = Icons.phone_outlined;
                    break;
                  case 'EMAIL':
                  case 'EMAILED':
                    eventColor = Colors.blue;
                    eventIcon = Icons.email_outlined;
                    break;
                  case 'STATUS_CHANGED':
                  case 'STATUS_UPDATE':
                    eventColor = Colors.orange;
                    eventIcon = Icons.swap_horiz;
                    break;
                  default:
                    eventColor = AppColors.primary;
                    eventIcon = Icons.circle_outlined;
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline indicator
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            // Dot indicator
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: eventColor,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: eventColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                eventIcon,
                                size: 20,
                                color: eventColor,
                              ),
                            ),
                            // Connecting line
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.only(top: 6),
                                  color: Colors.grey[300],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Content card
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Action and timestamp
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: eventColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        event.action
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: eventColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 13,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(event.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (event.details != null &&
                                  event.details!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  event.details!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              if (event.actorName != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 15,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      event.actorName!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
}
