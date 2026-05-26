import 'package:flutter/material.dart';
import 'package:crm_admin/core/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          const Text(
            'Getting Started',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn how to use CRM Admin effectively',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildHelpSection(
            title: 'Managing Leads',
            icon: Icons.people_outline,
            items: [
              _HelpItem(
                title: 'View Leads',
                description: 'Navigate to the Leads section from the home screen to view all leads. Use filters to search by name, phone, or status.',
              ),
              _HelpItem(
                title: 'Add New Lead',
                description: 'Tap the "+" button on the Leads screen to add a new lead. Fill in all required information including name, phone, email, and source.',
              ),
              _HelpItem(
                title: 'Assign Leads',
                description: 'Select multiple leads using checkboxes, then tap "Assign Leads" to assign them to employees. You can assign in batches for efficiency.',
              ),
              _HelpItem(
                title: 'Lead Details',
                description: 'Tap on any lead to view complete details. You can call, WhatsApp, or email directly from the lead detail screen.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: 'Managing Employees',
            icon: Icons.badge_outlined,
            items: [
              _HelpItem(
                title: 'View Employees',
                description: 'Access the Employees section to view all team members. Check their assigned leads and performance.',
              ),
              _HelpItem(
                title: 'Add Employee',
                description: 'Use the "+" button to add new employees. Enter their personal information, contact details, and assign appropriate permissions.',
              ),
              _HelpItem(
                title: 'Employee Performance',
                description: 'Track each employee\'s assigned leads and conversion rates from their detail page.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: 'User Management',
            icon: Icons.admin_panel_settings_outlined,
            items: [
              _HelpItem(
                title: 'Create Users',
                description: 'Both admins and sub-admins can create new employee users. Only admins can create admin or sub-admin accounts.',
              ),
              _HelpItem(
                title: 'Role Permissions',
                description: 'Admins: Can create employees, sub-admins, and other admins\nSub-Admins: Can create employees only (cannot create admin or sub-admin users)',
              ),
              _HelpItem(
                title: 'User Login',
                description: 'Select your role (Admin or Sub-Admin) when logging in. You must select the correct role matching your account.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: 'Communication Features',
            icon: Icons.phone_outlined,
            items: [
              _HelpItem(
                title: 'Quick Actions',
                description: 'Use the phone icon to call, WhatsApp icon for messaging, and email icon to compose emails directly from the app.',
              ),
              _HelpItem(
                title: 'Contact Integration',
                description: 'All contact actions open the respective apps on your device. Ensure WhatsApp and email apps are installed.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: 'Profile & Settings',
            icon: Icons.settings_outlined,
            items: [
              _HelpItem(
                title: 'Update Profile',
                description: 'Access your profile from the home screen. View your account information and quick access to important features.',
              ),
              _HelpItem(
                title: 'Change Password',
                description: 'For security, contact your administrator to change your password.',
              ),
              _HelpItem(
                title: 'Logout',
                description: 'Use the logout button on your profile page to securely sign out of the app.',
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visit the Support page to contact our team',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/support');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required IconData icon,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildHelpItem(item)),
      ],
    );
  }

  Widget _buildHelpItem(_HelpItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              item.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String title;
  final String description;

  _HelpItem({required this.title, required this.description});
}
