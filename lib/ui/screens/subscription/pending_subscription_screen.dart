import 'package:flutter/material.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/ui/screens/auth/login_screen.dart';

class PendingSubscriptionScreen extends StatelessWidget {
  const PendingSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty,
                          size: 60,
                          color: AppColors.warning,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Subscription Pending',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your subscription request has been successfully submitted!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Please wait while our team reviews your request. You will be notified once your subscription is approved.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Waiting for approval...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Logout button
                OutlinedButton.icon(
                  onPressed: () async {
                    // Clear session data
                    await PrefManager.clear();
                    
                    // Navigate to login screen
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
