import 'dart:developer' as dev;
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/subscription/subscription_models.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  Future<SubscriptionDetails?> getUserSubscription(String userId) async {
    try {
      dev.log(
        '📡 [SubscriptionRepository] Fetching subscription for user: $userId',
        name: 'SUBSCRIPTION',
      );
      final response = await _apiClient.get(
        ApiEndpoints.getUserSubscription(userId),
      );
      dev.log(
        '✅ [SubscriptionRepository] Response: ${response.data}',
        name: 'SUBSCRIPTION',
      );

      final data = response.data['data'];
      if (data == null) {
        dev.log(
          '⚠️ [SubscriptionRepository] No subscription data found',
          name: 'SUBSCRIPTION',
        );
        return null;
      }

      final subscription = SubscriptionDetails.fromJson(data);
      dev.log(
        '📦 [SubscriptionRepository] Subscription: Plan=${subscription.planName}, Expired=${subscription.expired}, DaysRemaining=${subscription.daysRemaining}',
        name: 'SUBSCRIPTION',
      );

      return subscription;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionRepository] Error fetching subscription: $e',
        name: 'SUBSCRIPTION',
      );
      rethrow;
    }
  }

  Future<PricingData> getPricing() async {
    try {
      dev.log(
        '📡 [SubscriptionRepository] Fetching pricing data...',
        name: 'SUBSCRIPTION',
      );
      final response = await _apiClient.get(ApiEndpoints.subscriptionPricing);
      dev.log(
        '✅ [SubscriptionRepository] Response: ${response.data}',
        name: 'SUBSCRIPTION',
      );

      final pricing = PricingData.fromJson(response.data['data']);
      dev.log(
        '📦 [SubscriptionRepository] Pricing: Admin: ${pricing.adminFee}, SubAdmin: ${pricing.subAdminPrice}, Employee: ${pricing.employeePrice}',
        name: 'SUBSCRIPTION',
      );

      return pricing;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionRepository] Error fetching pricing: $e',
        name: 'SUBSCRIPTION',
      );
      rethrow;
    }
  }

  Future<CostEstimate> estimateCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    try {
      dev.log(
        '📡 [SubscriptionRepository] Estimating custom plan: SubAdmins=$numSubAdmins, Employees=$numEmployees, Days=$subscriptionDurationDays',
        name: 'SUBSCRIPTION',
      );
      final response = await _apiClient.post(
        ApiEndpoints.estimateCustomPlan,
        data: {
          'numSubAdmins': numSubAdmins,
          'numEmployees': numEmployees,
          'subscriptionDurationDays': subscriptionDurationDays,
        },
      );
      dev.log(
        '✅ [SubscriptionRepository] Response: ${response.data}',
        name: 'SUBSCRIPTION',
      );

      final estimate = CostEstimate.fromJson(response.data['data']);
      dev.log(
        '📦 [SubscriptionRepository] Estimate: Total=${estimate.totalCost}, Breakdown=${estimate.breakdown}',
        name: 'SUBSCRIPTION',
      );

      return estimate;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionRepository] Error estimating plan: $e',
        name: 'SUBSCRIPTION',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    try {
      dev.log(
        '📡 [SubscriptionRepository] Requesting custom plan: SubAdmins=$numSubAdmins, Employees=$numEmployees, Days=$subscriptionDurationDays',
        name: 'SUBSCRIPTION',
      );
      final response = await _apiClient.post(
        ApiEndpoints.requestCustomPlan,
        data: {
          'numSubAdmins': numSubAdmins,
          'numEmployees': numEmployees,
          'subscriptionDurationDays': subscriptionDurationDays,
        },
      );
      dev.log(
        '✅ [SubscriptionRepository] Response: ${response.data}',
        name: 'SUBSCRIPTION',
      );

      return response.data['data'];
    } catch (e) {
      dev.log(
        '❌ [SubscriptionRepository] Error requesting custom plan: $e',
        name: 'SUBSCRIPTION',
      );
      rethrow;
    }
  }

  Future<List<SubscriptionRequest>> getMyRequests() async {
    try {
      dev.log(
        '📡 [SubscriptionRepository] Fetching my subscription requests...',
        name: 'SUBSCRIPTION',
      );
      final response = await _apiClient.get(
        ApiEndpoints.mySubscriptionRequests,
      );
      dev.log(
        '✅ [SubscriptionRepository] Response: ${response.data}',
        name: 'SUBSCRIPTION',
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final requests = data
          .map((json) => SubscriptionRequest.fromJson(json))
          .toList();
      dev.log(
        '📦 [SubscriptionRepository] Found ${requests.length} requests',
        name: 'SUBSCRIPTION',
      );

      return requests;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionRepository] Error fetching requests: $e',
        name: 'SUBSCRIPTION',
      );
      rethrow;
    }
  }
}
