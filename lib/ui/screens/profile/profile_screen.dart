import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/ui/screens/auth/login_screen.dart';
import 'package:crm_admin/ui/screens/leads/view_leads_screen.dart';
import 'package:crm_admin/ui/screens/leads/batch_assign_leads_screen.dart';
import 'package:crm_admin/ui/screens/leads/upload_excel_screen.dart';
import 'package:crm_admin/ui/screens/subscription/my_subscription_screen.dart';
import 'package:crm_admin/ui/screens/profile/about_screen.dart';
import 'package:crm_admin/ui/screens/profile/support_screen.dart';
import 'package:crm_admin/ui/screens/profile/help_screen.dart';
import 'package:crm_admin/ui/screens/profile/privacy_policy_screen.dart';
import 'package:crm_admin/ui/screens/notifications/notification_test_screen.dart';
import 'package:crm_admin/ui/screens/notifications/notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final username = PrefManager.getUsername() ?? 'Admin';
    final email = PrefManager.getEmail() ?? 'admin@company.com';
    final role = PrefManager.getRole() ?? 'ADMIN';
    final tenantId = PrefManager.getTenantId() ?? 'N/A';
    final fullName = PrefManager.getFullName() ?? username;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(fullName, email, role),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildAccountSection(username, tenantId),
                const SizedBox(height: 16),
                _buildSettingsSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String fullName, String email, String role) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                _getRoleDisplay(role),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.list_alt,
                  title: 'All Leads',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewLeadsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.batch_prediction,
                  title: 'Batch Assign',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BatchAssignLeadsScreen(),
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
                child: _buildActionCard(
                  icon: Icons.upload_file,
                  title: 'Upload Excel',
                  color: AppColors.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadExcelScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Hide subscription for sub-admin users
              if (PrefManager.getRole() != 'SUB_ADMIN')
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.card_membership,
                    title: 'My Subscription',
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MySubscriptionScreen(),
                      ),
                    ),
                  ),
                ),
              // Add spacing for sub-admin to maintain layout
              if (PrefManager.getRole() == 'SUB_ADMIN')
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(String username, String tenantId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.account_circle,
              label: 'Username',
              value: username,
              iconColor: AppColors.primary,
            ),
            _buildInfoTile(
              icon: Icons.business,
              label: 'ID',
              value: tenantId,
              iconColor: AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            // _buildSettingsTile(
            //   icon: Icons.card_membership,
            //   title: 'My Subscription',
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => const MySubscriptionScreen()),
            //   ),
            // ),
            _buildSettingsTile(
              icon: Icons.notifications_active,
              title: 'Notifications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.support_agent,
              title: 'Support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.textSecondary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'ADMIN':
        return '👑 Administrator';
      case 'SUB_ADMIN':
        return '⭐ Sub Admin';
      case 'EMPLOYEE':
        return '👤 Employee';
      default:
        return role;
    }
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
