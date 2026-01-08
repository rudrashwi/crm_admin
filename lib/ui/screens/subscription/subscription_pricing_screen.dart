import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/ui/screens/auth/login_screen.dart';
import 'package:crm_admin/ui/screens/subscription/pending_subscription_screen.dart';

class SubscriptionPricingScreen extends StatefulWidget {
  const SubscriptionPricingScreen({super.key});

  @override
  State<SubscriptionPricingScreen> createState() =>
      _SubscriptionPricingScreenState();
}

class _SubscriptionPricingScreenState extends State<SubscriptionPricingScreen> {
  final _subAdminsController = TextEditingController(text: '1');
  final _employeesController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchPricing();
    });
  }

  @override
  void dispose() {
    _subAdminsController.dispose();
    _employeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<SubscriptionProvider>().fetchPricing(),
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pricing == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.pricing == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchPricing(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final pricing = provider.pricing;
          if (pricing == null) {
            return const Center(child: Text('No pricing data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.workspace_premium,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Choose Your Plan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Flexible pricing for teams of all sizes',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pricing Cards
                _buildPricingCard(
                  'Admin Fee',
                  '₹${pricing.adminFee.toStringAsFixed(2)}',
                  'One-time setup fee',
                  Icons.admin_panel_settings,
                  AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildPricingCard(
                  'Sub-Admin',
                  '₹${pricing.subAdminPrice.toStringAsFixed(2)}',
                  'Per sub-admin per month',
                  Icons.supervisor_account,
                  AppColors.warning,
                ),
                const SizedBox(height: 12),
                _buildPricingCard(
                  'Employee',
                  '₹${pricing.employeePrice.toStringAsFixed(2)}',
                  'Per employee per month',
                  Icons.person,
                  AppColors.info,
                ),
                const SizedBox(height: 32),

                // Custom Plan Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Plan Calculator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _subAdminsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of Sub-Admins',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.supervisor_account),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _employeesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of Employees',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Estimate Display
                      if (provider.estimate != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Estimated Cost',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${provider.estimate!.totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.estimate!.breakdown,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : _estimatePlan,
                              icon: const Icon(Icons.calculate),
                              label: const Text('Estimate'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : _requestPlan,
                              icon: const Icon(Icons.send),
                              label: const Text('Request Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 32),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _estimatePlan() async {
    final subAdmins = int.tryParse(_subAdminsController.text) ?? 0;
    final employees = int.tryParse(_employeesController.text) ?? 0;

    if (subAdmins < 0 || employees < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    final success = await context
        .read<SubscriptionProvider>()
        .estimateCustomPlan(
          numSubAdmins: subAdmins,
          numEmployees: employees,
          subscriptionDurationDays: 30, // Default 1 month
        );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${context.read<SubscriptionProvider>().error}'),
        ),
      );
    }
  }

  Future<void> _requestPlan() async {
    final subAdmins = int.tryParse(_subAdminsController.text) ?? 0;
    final employees = int.tryParse(_employeesController.text) ?? 0;

    if (subAdmins < 0 || employees < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Request'),
        content: Text(
          'Request subscription for:\n• $subAdmins Sub-Admins\n• $employees Employees\n• Duration: 1 Month (30 days)\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context
        .read<SubscriptionProvider>()
        .requestCustomPlan(
          numSubAdmins: subAdmins,
          numEmployees: employees,
          subscriptionDurationDays: 30, // Default 1 month
        );

    if (!mounted) return;
    if (success) {
      // Navigate to pending screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingSubscriptionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${context.read<SubscriptionProvider>().error}'),
        ),
      );
    }
  }
}
