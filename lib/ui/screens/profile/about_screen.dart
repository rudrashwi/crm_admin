import 'package:flutter/material.dart';
import 'package:crm_admin/core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RudraCRM Admin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional Management Suite',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'About This App',
              description:
                  'CRM Admin is a comprehensive customer relationship management system designed for administrators and sub-admins to efficiently manage leads, employees, and business operations.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.stars_outlined,
              title: 'Key Features',
              description:
                  '• Lead Management\n• Employee Management\n• Batch Lead Assignment\n• Real-time Analytics\n• Role-based Access Control\n• User Activity Tracking',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.security,
              title: 'Security',
              description:
                  'Your data is secured with industry-standard encryption. We prioritize your privacy and ensure all information is handled with the utmost care.',
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              '© 2026 CRM Admin. All rights reserved.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
