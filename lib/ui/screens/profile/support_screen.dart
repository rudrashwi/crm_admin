import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get in touch with our support team',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@crmadmin.com',
              description: 'We\'ll respond within 24 hours',
              onTap: () => _launchUrl('mailto:support@crmadmin.com'),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+1 (555) 123-4567',
              description: 'Mon-Fri, 9:00 AM - 6:00 PM',
              onTap: () => _launchUrl('tel:+15551234567'),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              iconWidget: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
              title: 'WhatsApp Support',
              subtitle: '+1 (555) 123-4567',
              description: 'Quick responses during business hours',
              onTap: () => _launchUrl('https://wa.me/15551234567'),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.language,
              title: 'Help Center',
              subtitle: 'Visit our online help center',
              description: 'Find guides, FAQs, and tutorials',
              onTap: () => _launchUrl('https://help.crmadmin.com'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'How do I reset my password?',
              answer: 'Contact your administrator to reset your password. For security reasons, passwords can only be reset through the admin panel.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'What\'s the difference between Admin and Sub-Admin?',
              answer: 'Admins have full access including creating employees, sub-admins, and other admins. Sub-Admins can manage leads and employees, and can create employee accounts, but cannot create new admin or sub-admin users.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'How do I assign leads?',
              answer: 'Navigate to the Leads section, select the leads you want to assign, and use the "Assign Leads" option to assign them to employees.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'Can I export data?',
              answer: 'Yes, data export features are available in the respective sections. Contact support if you need help with data export.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconWidget ?? Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
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
