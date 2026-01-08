import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = PrefManager.getUserId();
      if (userId != null && userId.isNotEmpty) {
        context.read<SubscriptionProvider>().fetchUserSubscription(userId);
        context.read<SubscriptionProvider>().fetchMyRequests();
      }
    });
  }

  Future<void> _refresh() async {
    final userId = PrefManager.getUserId();
    if (userId != null && userId.isNotEmpty) {
      await context.read<SubscriptionProvider>().fetchUserSubscription(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.subscription == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.subscription == null) {
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
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final subscription = provider.subscription;
          if (subscription == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.card_membership,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Subscription Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don\'t have an active subscription',
                    style: TextStyle(color: AppColors.textSecondary),
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
                  _buildStatusCard(subscription),
                  const SizedBox(height: 16),
                  _buildPlanInfoCard(subscription),
                  const SizedBox(height: 16),
                  _buildLimitsCard(subscription),
                  const SizedBox(height: 16),
                  _buildUsageCard(subscription),
                  const SizedBox(height: 16),
                  _buildUpdateSubscriptionButton(context),
                  const SizedBox(height: 16),
                  _buildMyRequestsSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(subscription) {
    final isExpired = subscription.expired;
    final daysRemaining = subscription.daysRemaining ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [AppColors.error, AppColors.error.withOpacity(0.8)]
              : [AppColors.success, AppColors.success.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? AppColors.error : AppColors.success)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isExpired ? Icons.warning_rounded : Icons.verified_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isExpired ? 'Subscription Expired' : 'Active Subscription',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (!isExpired) ...[
            Text(
              subscription.remainingTime ?? '$daysRemaining days remaining',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ] else ...[
            const Text(
              'Please renew your subscription',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanInfoCard(subscription) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Plan Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // const SizedBox(height: 16),
          // _buildInfoRow('Plan Name', subscription.planName ?? 'N/A', Icons.card_membership),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Start Date',
            subscription.startDate != null
                ? DateFormat('MMM dd, yyyy').format(subscription.startDate!)
                : 'N/A',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'End Date',
            subscription.endDate != null
                ? DateFormat('MMM dd, yyyy').format(subscription.endDate!)
                : 'N/A',
            Icons.event,
          ),
          if (subscription.ownerName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Owner', subscription.ownerName!, Icons.person),
          ],
          if (subscription.adminName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Admin',
              subscription.adminName!,
              Icons.admin_panel_settings,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitsCard(subscription) {
    final limits = subscription.limits;
    if (limits == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.speed,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Subscription Limits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLimitTile(
                  'Employees',
                  limits.employees ?? 0,
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLimitTile(
                  'Sub-Admins',
                  limits.subAdmins ?? 0,
                  Icons.supervisor_account,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLimitTile(
                  'Leads',
                  limits.leads ?? 0,
                  Icons.contacts,
                  AppColors.info,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 12),
          // _buildLimitTile('Leads', limits.leads ?? 0, Icons.contacts, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildUsageCard(subscription) {
    final usage = subscription.usage;
    final limits = subscription.limits;
    if (usage == null || limits == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Current Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildUsageBar(
            'Employees',
            usage.employees ?? 0,
            limits.employees ?? 0,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildUsageBar(
            'Sub-Admins',
            usage.subAdmins ?? 0,
            limits.subAdmins ?? 0,
            AppColors.warning,
          ),
          const SizedBox(height: 16),
          _buildUsageBar(
            'Leads',
            usage.leads ?? 0,
            limits.leads ?? 0,
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitTile(String label, int limit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
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
            limit.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(String label, int used, int total, Color color) {
    final percentage = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$used / $total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateSubscriptionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showUpdateSubscriptionDialog(context),
        icon: const Icon(Icons.upgrade),
        label: const Text('Update Subscription'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsSection() {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.read<SubscriptionProvider>().fetchMyRequests();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoading && provider.myRequests.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.myRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No subscription requests yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...provider.myRequests.map(
                (request) => _buildRequestCard(request),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'APPROVED':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(request.createdAt))}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${request.estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRequestDetail(
                  'Sub-Admins',
                  request.numSubAdmins.toString(),
                  Icons.supervisor_account,
                ),
                _buildRequestDetail(
                  'Employees',
                  request.numEmployees.toString(),
                  Icons.people,
                ),
                _buildRequestDetail(
                  'Duration',
                  '${request.durationMonths} month(s)',
                  Icons.calendar_month,
                ),
              ],
            ),
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${request.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showUpdateSubscriptionDialog(BuildContext context) {
    final parentContext = context;
    final subAdminsController = TextEditingController(text: '0');
    final employeesController = TextEditingController(text: '1');
    String selectedDuration = '1 Month'; // Default to 1 month

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Subscription'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: subAdminsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Sub-Admins',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: employeesController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Employees',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subscription Duration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedDuration,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '1 Month',
                          child: Text('1 Month (30 days)'),
                        ),
                        DropdownMenuItem(
                          value: '1 Year',
                          child: Text('1 Year (365 days)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDuration = value ?? '1 Month';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final numSubAdmins =
                        int.tryParse(subAdminsController.text) ?? 0;
                    final numEmployees =
                        int.tryParse(employeesController.text) ?? 0;
                    final durationDays = selectedDuration == '1 Year'
                        ? 365
                        : 30;

                    if (numEmployees <= 0) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Employees must be at least 1'),
                        ),
                      );
                      return;
                    }
                    if (numSubAdmins < 0) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid numbers'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    _showEstimateAndConfirm(
                      parentContext,
                      numSubAdmins,
                      numEmployees,
                      durationDays,
                    );
                  },
                  child: const Text('Get Estimate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEstimateAndConfirm(
    BuildContext context,
    int numSubAdmins,
    int numEmployees,
    int durationDays,
  ) async {
    final provider = context.read<SubscriptionProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.estimateCustomPlan(
      numSubAdmins: numSubAdmins,
      numEmployees: numEmployees,
      subscriptionDurationDays: durationDays,
    );

    if (!mounted) return;
    try {
      Navigator.of(context).pop(); // Close loading
    } catch (_) {}

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error ?? "Failed to get estimate"}'),
        ),
      );
      return;
    }

    // Show estimate dialog
    showDialog(
      context: context,
      builder: (dialogContext) {
        final estimate = provider.estimate;
        if (estimate == null) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load estimate'),
            actions: [
              TextButton(
                onPressed: () {
                  try {
                    Navigator.pop(dialogContext);
                  } catch (_) {}
                },
                child: const Text('OK'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Subscription Estimate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sub-Admins: $numSubAdmins'),
                Text('Employees: $numEmployees'),
                Text(
                  'Duration: ${durationDays == 365 ? "1 Year" : "1 Month"} ($durationDays days)',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Total Cost: ₹${estimate.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                if (estimate.breakdown.isNotEmpty) ...[
                  const Text(
                    'Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(estimate.breakdown),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  Navigator.pop(dialogContext);
                } catch (_) {}
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(dialogContext);
                } catch (_) {}
                await _confirmAndSubmitRequest(
                  context,
                  numSubAdmins,
                  numEmployees,
                  durationDays,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndSubmitRequest(
    BuildContext context,
    int numSubAdmins,
    int numEmployees,
    int durationDays,
  ) async {
    final provider = context.read<SubscriptionProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.requestCustomPlan(
      numSubAdmins: numSubAdmins,
      numEmployees: numEmployees,
      subscriptionDurationDays: durationDays,
    );

    if (!mounted) return;
    try {
      Navigator.of(context).pop(); // Close loading
    } catch (_) {}

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription request submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh requests
      provider.fetchMyRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${provider.error ?? "Failed to submit request"}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
