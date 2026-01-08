import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class SubAdminDetailScreen extends StatefulWidget {
  final UserModel user;
  const SubAdminDetailScreen({super.key, required this.user});

  @override
  State<SubAdminDetailScreen> createState() => _SubAdminDetailScreenState();
}

class _SubAdminDetailScreenState extends State<SubAdminDetailScreen> {
  @override
  void initState() {
    super.initState();
    _localIsActive = widget.user.isActive;
    if (widget.user.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserProvider>().fetchEmployeeDetails(widget.user.id);
      });
    }
  }

  bool _localIsActive = true;

  Future<void> _refresh() {
    if (widget.user.id.isEmpty) return Future.value();
    return context.read<UserProvider>().fetchEmployeeDetails(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
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
                  if (detail != null) ...[
                    _buildStats(detail),
                    const SizedBox(height: 24),
                    _buildPermissionsCard(),
                    const SizedBox(height: 16),
                    _buildTeamMembersCard(detail),
                  const SizedBox(height: 16),
                  _buildActionButtons(detail),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(detail) {
    final isActive = detail?.isActive ?? _localIsActive;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning,
            AppColors.warning.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
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
              widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.warning,
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
                  '@${widget.user.username}',
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
                      icon: const Icon(Icons.email, color: Colors.white70, size: 18),
                      tooltip: 'Send Email',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (widget.user.mobileNumber != null && widget.user.mobileNumber!.isNotEmpty) ...[
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
                        onPressed: () => _makePhoneCall(widget.user.mobileNumber!),
                        icon: const Icon(Icons.call, color: Colors.white70, size: 18),
                        tooltip: 'Call',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openWhatsApp(widget.user.mobileNumber!),
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white70, size: 18),
                        tooltip: 'WhatsApp',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _badge('SUB-ADMIN', Colors.white),
                    _badge(isActive ? 'ACTIVE' : 'INACTIVE', isActive ? AppColors.success : AppColors.error),
                    if (detail?.managerName != null)
                      _badge('Reports to: ${detail!.managerName}', Colors.white70),
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
    final currentUserRole = PrefManager.getRole() ?? 'ADMIN';
    final isCurrentUserAdmin = currentUserRole == 'ADMIN';
    
    // Sub-admins cannot terminate other sub-admins
    if (!isCurrentUserAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.info, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Only administrators can terminate sub-admin accounts',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: isActive 
              ? () => _showTerminateDialog() 
              : () => _showReactivateDialog(),
          icon: Icon(isActive ? Icons.person_off : Icons.person_add, size: 20),
          label: Text(isActive ? 'Terminate Sub-Admin' : 'Reactivate Sub-Admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppColors.error : AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (newPassController.text.isEmpty) return;
            if (newPassController.text != confirmController.text) return;
            Navigator.pop(context, true);
          }, child: const Text('Reset')),
        ],
      ),
    );

    if (confirmed == true) {
      final newPass = newPassController.text;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resetting password...')));
      final success = await context.read<UserProvider>().resetPassword(widget.user.id, newPass);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<UserProvider>().error}')));
      }
    }
  }

  Widget _buildStats(detail) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          'Total Leads',
          detail.totalAssignedLeads.toString(),
          Icons.work_outline,
          AppColors.primary,
        ),
        _statCard(
          'Active',
          detail.activeLeads.toString(),
          Icons.timelapse,
          AppColors.warning,
        ),
        _statCard(
          'Closed',
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

  Widget _statCard(String title, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2;
    
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _buildPermissionsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppColors.warning, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Permissions & Access',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _permissionItem(Icons.check_circle, 'Manage Team Members', true),
            _permissionItem(Icons.check_circle, 'View All Leads', true),
            _permissionItem(Icons.check_circle, 'Assign Leads', true),
            _permissionItem(Icons.check_circle, 'View Reports', true),
            _permissionItem(Icons.cancel, 'System Configuration', false),
            _permissionItem(Icons.cancel, 'Billing Access', false),
          ],
        ),
      ),
    );
  }

  Widget _permissionItem(IconData icon, String text, bool granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: granted ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: granted ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersCard(detail) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Performance Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Managed Leads',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  detail.totalAssignedLeads.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conversion Rate',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '${detail.conversionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: detail.conversionRate >= 50 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Leads',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  detail.activeLeads.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTerminateDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Sub-Admin'),
        content: Text('Are you sure you want to terminate ${widget.user.fullName}? They will no longer have access to the system.'),
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
      final success = await context.read<UserProvider>().terminateUser(widget.user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sub-Admin terminated successfully'),
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
        title: const Text('Reactivate Sub-Admin'),
        content: Text('Are you sure you want to reactivate ${widget.user.fullName}?'),
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
      final success = await context.read<UserProvider>().reactivateUser(widget.user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sub-Admin reactivated successfully'),
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

  Future<void> _openEmail(String email) async {
    try {
      final uri = Uri(scheme: 'mailto', path: email);
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app. Make sure one is installed.')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
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
          const SnackBar(content: Text('Could not open WhatsApp. Make sure it is installed.')),
        );
      }
    }
  }
}
