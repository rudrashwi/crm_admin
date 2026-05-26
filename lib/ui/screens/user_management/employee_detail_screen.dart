import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/permission_provider.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final UserModel user;
  const EmployeeDetailScreen({super.key, required this.user});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    _localIsActive = widget.user.isActive;
    if (widget.user.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Fetch employee details
        context.read<UserProvider>().fetchEmployeeDetails(widget.user.id);
        // Check permission status
        context.read<PermissionProvider>().checkPermission(widget.user.id);
      });
    }
  }

  bool _localIsActive = true;

  Future<void> _refresh() {
    if (widget.user.id.isEmpty) return Future.value();
    // Refresh both employee details and permission status
    return Future.wait([
      context.read<UserProvider>().fetchEmployeeDetails(widget.user.id),
      context.read<PermissionProvider>().checkPermission(widget.user.id).then((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
        title: Text(widget.user.fullName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          final detail = provider.selectedEmployee;

          if (provider.isLoading && detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && detail == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(detail),
                  const SizedBox(height: 16),
                  _buildActionButtons(detail),
                  const SizedBox(height: 16),
                  if (detail != null) ...[
                    _buildStats(detail),
                    const SizedBox(height: 24),
                    _buildMissedFollowUps(detail),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => _showAssignLeadsBottomSheet(context),
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Assign Leads',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (detail.recentLeads.isNotEmpty) ...[
                      ...detail.recentLeads.map(
                        (lead) => InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LeadDetailScreen(leadId: lead.id),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _getStatusColor(
                                  lead.status,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 5,
                                top: 1,
                                bottom: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lead.customerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(lead.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                lead.status,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(lead.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Material(
                                        elevation: 2,
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                        child: InkWell(
                                          onTap: () => _unassignLead(lead.id),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.error.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.link_off_rounded,
                                                  size: 18,
                                                  color: AppColors.error,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Unassign',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Assigned: ${_formatDate(lead.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.update,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Updated: ${_formatDate(lead.updatedAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No recent leads',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
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
    );
  }

  Widget _buildHeader(detail) {
    final isActive = detail?.isActive ?? _localIsActive;
    final role = detail?.role ?? widget.user.role;
    final isSubAdmin = role == 'SUB_ADMIN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isSubAdmin ? AppColors.warning : AppColors.primary,
            (isSubAdmin ? AppColors.warning : AppColors.primary).withOpacity(
              0.7,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isSubAdmin ? AppColors.warning : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              widget.user.fullName.isNotEmpty
                  ? widget.user.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: isSubAdmin ? AppColors.warning : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail?.employeeName ?? widget.user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.user.username}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.user.email,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openEmail(widget.user.email),
                      icon: const Icon(
                        Icons.email,
                        color: Colors.white70,
                        size: 18,
                      ),
                      tooltip: 'Send Email',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (widget.user.mobileNumber != null &&
                    widget.user.mobileNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white60, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.user.mobileNumber!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _makePhoneCall(widget.user.mobileNumber!),
                        icon: const Icon(
                          Icons.call,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: 'Call',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            _openWhatsApp(widget.user.mobileNumber!),
                        icon: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: 'WhatsApp',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
                // const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _badge(isSubAdmin ? 'SUB-ADMIN' : 'EMPLOYEE', Colors.white),
                    _badge(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      isActive ? AppColors.success : AppColors.error,
                    ),
                    if (detail?.managerName != null)
                      _badge('Manager: ${detail!.managerName}', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(detail) {
    final isActive = detail?.isActive ?? _localIsActive;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAssignLeadsBottomSheet(context),
                icon: const Icon(Icons.assignment_add, size: 20),
                label: const Text('Assign Leads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isActive
                    ? () => _showTerminateDialog()
                    : () => _showReactivateDialog(),
                icon: Icon(
                  isActive ? Icons.person_off : Icons.person_add,
                  size: 20,
                ),
                label: Text(isActive ? 'Terminate' : 'Reactivate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive
                      ? AppColors.error
                      : AppColors.success,
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
        // Only ADMIN can reset passwords
        if (PrefManager.getRole() == 'ADMIN')
          OutlinedButton.icon(
            onPressed: () => _showResetPasswordDialog(),
            icon: const Icon(Icons.lock_reset),
            label: const Text('Reset Password'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        // Permission toggle for employees only
        if (widget.user.role == 'EMPLOYEE') ...[
          const SizedBox(height: 12),
          Consumer<PermissionProvider>(
            builder: (context, permissionProvider, _) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Can Create Leads',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Allow employee to create their own leads',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer2<UserProvider, PermissionProvider>(
                        builder: (context, userProvider, permissionProvider, _) {
                          final detail = userProvider.selectedEmployee;
                          // First check the permission cache, then fall back to employee detail or user model
                          final cachedPermission = permissionProvider.getPermissionFromCache(widget.user.id);
                          final currentValue = cachedPermission 
                              ?? detail?.canCreateLeads 
                              ?? widget.user.canCreateLeads;
                          
                          return Switch(
                            value: currentValue,
                            onChanged: permissionProvider.isLoading
                                ? null
                                : (value) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    
                                    final success = await permissionProvider.toggleLeadCreationPermission(
                                      widget.user.id,
                                      currentValue,
                                    );
                                    
                                    if (success) {
                                      // Refresh the employee details and re-check permission
                                      await Future.wait([
                                        userProvider.fetchEmployeeDetails(widget.user.id),
                                        permissionProvider.checkPermission(widget.user.id).then((_) {}),
                                      ]);
                                  
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            value 
                                              ? 'Lead creation permission granted to ${widget.user.fullName}'
                                              : 'Lead creation permission revoked from ${widget.user.fullName}',
                                          ),
                                          backgroundColor: value ? AppColors.success : AppColors.warning,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (permissionProvider.error != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(permissionProvider.error!),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            activeColor: AppColors.success,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showResetPasswordDialog() async {
    final newPassController = TextEditingController();
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPassController.text.isEmpty) return;
              if (newPassController.text != confirmController.text) return;
              Navigator.pop(context, true);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newPass = newPassController.text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resetting password...')));
      final success = await context.read<UserProvider>().resetPassword(
        widget.user.id,
        newPass,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${context.read<UserProvider>().error}'),
          ),
        );
      }
    }
  }

  Widget _buildStats(detail) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          'Total Assigned',
          detail.totalAssignedLeads.toString(),
          Icons.work_outline,
          AppColors.primary,
        ),
        _statCard(
          'Active Leads',
          detail.activeLeads.toString(),
          Icons.timelapse,
          AppColors.warning,
        ),
        _statCard(
          'Closed Leads',
          detail.closedLeads.toString(),
          Icons.check_circle,
          AppColors.success,
        ),
        _statCard(
          'Conversion',
          '${detail.conversionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildMissedFollowUps(detail) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> missedFollowUps = [];

    // Collect all missed follow-ups from recent leads
    for (final lead in detail.recentLeads) {
      if (lead.followUps != null) {
        for (final followUp in lead.followUps!) {
          // Check if follow-up is missed
          if (followUp.status != 'COMPLETED' && followUp.status != 'CANCELLED') {
            if (followUp.scheduledDateTime != null) {
              try {
                final scheduledTime = DateTime.parse(followUp.scheduledDateTime!);
                if (scheduledTime.isBefore(now)) {
                  missedFollowUps.add({
                    'followUp': followUp,
                    'lead': lead,
                  });
                }
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
        }
      }
    }

    // Sort by scheduled time (oldest first)
    missedFollowUps.sort((a, b) {
      final aTime = DateTime.parse(a['followUp'].scheduledDateTime);
      final bTime = DateTime.parse(b['followUp'].scheduledDateTime);
      return aTime.compareTo(bTime);
    });

    if (missedFollowUps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Missed Follow-ups (${missedFollowUps.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...missedFollowUps.take(5).map((item) {
          final followUp = item['followUp'];
          final lead = item['lead'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            color: AppColors.error.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.error.withOpacity(0.3), width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeadDetailScreen(leadId: lead.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                            Icons.event_busy,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.contactName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lead: ${lead.id.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MISSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(
                            DateTime.parse(followUp.scheduledDateTime!),
                          )}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        followUp.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (missedFollowUps.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '+${missedFollowUps.length - 5} more missed follow-ups',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2; // 2 cards per row with padding

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _unassignLead(String leadId) async {
    final confirmation = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text('Are you sure you want to unassign this lead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Unassign',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      if (!mounted) return;
      final success = await context.read<LeadsProvider>().unassignLead(leadId);
      if (mounted) {
        if (success) {
          // Refresh employee details
          await context.read<UserProvider>().fetchEmployeeDetails(
            widget.user.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead unassigned successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<LeadsProvider>().error}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showAssignLeadsBottomSheet(BuildContext context) async {
    // Fetch leads before showing the bottom sheet
    final leadsProvider = context.read<LeadsProvider>();
    await leadsProvider.fetchLeads();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: _AssignLeadsBottomSheet(employeeId: widget.user.id),
      ),
    );
  }

  Future<void> _showTerminateDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Employee'),
        content: Text(
          'Are you sure you want to terminate ${widget.user.fullName}? They will no longer have access to the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<UserProvider>().terminateUser(
        widget.user.id,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee terminated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Update local active state and refresh users list asynchronously.
          setState(() => _localIsActive = false);
          // fire-and-forget refresh of users list
          context.read<UserProvider>().fetchUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<UserProvider>().error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showReactivateDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Employee'),
        content: Text(
          'Are you sure you want to reactivate ${widget.user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<UserProvider>().reactivateUser(
        widget.user.id,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee reactivated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() => _localIsActive = true);
          // fire-and-forget refresh of users list
          context.read<UserProvider>().fetchUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<UserProvider>().error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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

  Future<void> _makePhoneCall(String phone) async {
    await _makeCall(phone);
  }
}

class _AssignLeadsBottomSheet extends StatefulWidget {
  final String employeeId;
  const _AssignLeadsBottomSheet({required this.employeeId});

  @override
  State<_AssignLeadsBottomSheet> createState() =>
      _AssignLeadsBottomSheetState();
}

class _AssignLeadsBottomSheetState extends State<_AssignLeadsBottomSheet> {
  final List<String> _selectedLeadIds = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Consumer<LeadsProvider>(
          builder: (context, leadsProvider, _) {
            // Filter unassigned leads
            final availableLeads = leadsProvider.leads
                .where(
                  (lead) => lead.status == 'NEW' || lead.status == 'UNASSIGNED',
                )
                .toList();

            // Search filter
            final filteredLeads = _searchController.text.isEmpty
                ? availableLeads
                : availableLeads
                      .where(
                        (lead) =>
                            lead.customerName.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ) ||
                            lead.contactPhone.contains(_searchController.text),
                      )
                      .toList();

            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Assign Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_selectedLeadIds.length} selected',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Leads List
                Expanded(
                  child: leadsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredLeads.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No available leads to assign'
                                : 'No leads found',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            bottom: 80 + MediaQuery.of(context).viewPadding.bottom,
                          ),
                          itemCount: filteredLeads.length,
                          itemBuilder: (context, index) {
                            final lead = filteredLeads[index];
                            final isSelected = _selectedLeadIds.contains(
                              lead.id,
                            );

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedLeadIds.add(lead.id);
                                  } else {
                                    _selectedLeadIds.remove(lead.id);
                                  }
                                });
                              },
                              title: Text(
                                lead.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const SizedBox(height: 4),
                                  // Text(
                                  //   lead.requirementMessage,
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  //   style: const TextStyle(fontSize: 12),
                                  // ),
                                  // const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lead.contactPhone,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      // IconButton(
                                      //   onPressed: () =>
                                      //       _makeCall(lead.contactPhone),
                                      //   icon: const Icon(
                                      //     Icons.call,
                                      //     color: AppColors.success,
                                      //     size: 16,
                                      //   ),
                                      //   tooltip: 'Call',
                                      //   padding: EdgeInsets.zero,
                                      //   constraints: const BoxConstraints(),
                                      // ),
                                      // const SizedBox(width: 6),
                                      // IconButton(
                                      //   onPressed: () =>
                                      //       _openWhatsApp(lead.contactPhone),
                                      //   icon: const FaIcon(
                                      //     FontAwesomeIcons.whatsapp,
                                      //     color: Color(0xFF25D366),
                                      //     size: 16,
                                      //   ),
                                      //   tooltip: 'WhatsApp',
                                      //   padding: EdgeInsets.zero,
                                      //   constraints: const BoxConstraints(),
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: AppColors.info,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedLeadIds.isEmpty
                              ? null
                              : () => _assignSelectedLeads(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Assign'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignSelectedLeads(BuildContext context) async {
    final leadsProvider = context.read<LeadsProvider>();
    final userProvider = context.read<UserProvider>();

    try {
      final success = await leadsProvider.batchAssignLeads(_selectedLeadIds, [
        widget.employeeId,
      ]);

      if (mounted) {
        if (success) {
          // Refresh employee details
          await userProvider.fetchEmployeeDetails(widget.employeeId);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leads assigned successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${leadsProvider.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
}
