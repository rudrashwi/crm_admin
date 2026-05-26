import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/data/models/subscription/subscription_models.dart';
import 'package:crm_admin/data/repositories/subscription_repository.dart';
import 'package:crm_admin/core/api/api_client.dart';

class PendingRenewalRequestsScreen extends StatefulWidget {
  const PendingRenewalRequestsScreen({super.key});

  @override
  State<PendingRenewalRequestsScreen> createState() =>
      _PendingRenewalRequestsScreenState();
}

class _PendingRenewalRequestsScreenState
    extends State<PendingRenewalRequestsScreen> {
  late SubscriptionRepository _repository;
  List<RenewalRequest> _renewalRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SubscriptionRepository(ApiClient());
    _loadRenewalRequests();
  }

  Future<void> _loadRenewalRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _repository.getPendingRenewalRequests();
      setState(() {
        _renewalRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Renewal Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRenewalRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRenewalRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_renewalRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Pending Renewal Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All renewal requests have been processed',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRenewalRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _renewalRequests.length,
        itemBuilder: (context, index) {
          return _buildRenewalRequestCard(_renewalRequests[index]);
        },
      ),
    );
  }

  Widget _buildRenewalRequestCard(RenewalRequest request) {
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Plan Details
            _buildDetailRow(
              Icons.workspace_premium,
              'Plan Name',
              request.planName,
              AppColors.primary,
            ),
          //  const SizedBox(height: 12),
            // _buildDetailRow(
            //   Icons.confirmation_number,
            //   'Subscription ID',
            //   request.subscriptionId.substring(0, 13) + '...',
            //   AppColors.info,
            // ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Requested At',
              _formatDate(request.requestedAt),
              AppColors.textSecondary,
            ),

            // Approval/Rejection Info
            if (request.approvedAt != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.event_available,
                'Approved At',
                _formatDate(request.approvedAt!),
                AppColors.success,
              ),
            ],
            if (request.approvedBy != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.person,
                'Approved By',
                request.approvedBy!,
                AppColors.success,
              ),
            ],
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tenant Info
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenant ID',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.tenantId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
