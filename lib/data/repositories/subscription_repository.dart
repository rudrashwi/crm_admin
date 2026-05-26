import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/subscription/subscription_models.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  Future<SubscriptionDetails?> getUserSubscription(String userId) async {
    try {
      print('\n📡 [SubscriptionRepository] GET USER SUBSCRIPTION REQUEST:');
      print('   User ID: $userId');
      print('   Endpoint: ${ApiEndpoints.getUserSubscription(userId)}');

      final response = await _apiClient.get(
        ApiEndpoints.getUserSubscription(userId),
      );

      print('\n✅ [SubscriptionRepository] GET USER SUBSCRIPTION RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Timestamp: ${response.data['timestamp']}');

      final data = response.data['data'];
      if (data == null) {
        print('\n⚠️ [SubscriptionRepository] No subscription data found\n');
        return null;
      }

      print('\n📦 [SubscriptionRepository] SUBSCRIPTION DATA:');
      print('   Subscription ID: ${data['subscriptionId']}');
      print('   Plan: ${data['plan']}');
      print('   Plan Name: ${data['planName']}');
      print('   Start Date: ${data['startDate']}');
      print('   End Date: ${data['endDate']}');
      print('   Days Remaining: ${data['daysRemaining']}');
      print('   Remaining Time: ${data['remainingTime']}');
      print('   Is Expired: ${data['isExpired']}');
      print('   Is Trial: ${data['isTrial']}');
      print('   Status: ${data['status']}');

      if (data['trialInfo'] != null) {
        print('\n🔄 [SubscriptionRepository] TRIAL INFO:');
        print('   Is Trial Active: ${data['trialInfo']['isTrialActive']}');
        print('   Message: ${data['trialInfo']['message']}');
      }

      if (data['limits'] != null) {
        print('\n📊 [SubscriptionRepository] LIMITS:');
        print('   Employees: ${data['limits']['employees']}');
        print('   Sub-Admins: ${data['limits']['subAdmins']}');
      }

      if (data['usage'] != null) {
        print('\n📊 [SubscriptionRepository] USAGE:');
        print('   Employees: ${data['usage']['employees']}');
        print('   Sub-Admins: ${data['usage']['subAdmins']}');
        print('   Leads: ${data['usage']['leads']}');
      }

      if (data['remaining'] != null) {
        print('\n📊 [SubscriptionRepository] REMAINING:');
        print('   Employees: ${data['remaining']['employees']}');
        print('   Sub-Admins: ${data['remaining']['subAdmins']}');
      }

      final subscription = SubscriptionDetails.fromJson(data);
      print(
        '\n✨ [SubscriptionRepository] Subscription retrieved successfully\n',
      );

      return subscription;
    } catch (e) {
      print('\n❌ [SubscriptionRepository] GET USER SUBSCRIPTION ERROR: $e\n');
      rethrow;
    }
  }

  Future<PricingData> getPricing() async {
    try {
      print('\n📡 [SubscriptionRepository] GET PRICING REQUEST');
      print('   Endpoint: ${ApiEndpoints.subscriptionPricing}');

      final response = await _apiClient.get(ApiEndpoints.subscriptionPricing);

      print('\n✅ [SubscriptionRepository] GET PRICING RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');

      final pricingData = response.data['data'];
      print('\n📦 [SubscriptionRepository] PRICING DATA:');
      print('   ID: ${pricingData['id']}');
      print(
        '   Sub-Admin Price Per Day: ₹${pricingData['subAdminPricePerDay']}',
      );
      print(
        '   Employee Price Per Day: ₹${pricingData['employeePricePerDay']}',
      );
      print('   Created At: ${pricingData['createdAt']}');
      print('   Updated At: ${pricingData['updatedAt']}');

      final pricing = PricingData.fromJson(pricingData);
      print('\n✨ [SubscriptionRepository] Pricing retrieved successfully\n');

      return pricing;
    } catch (e) {
      print('\n❌ [SubscriptionRepository] GET PRICING ERROR: $e\n');
      rethrow;
    }
  }

  Future<CostEstimate> estimateCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    try {
      print('\n📡 [SubscriptionRepository] ESTIMATE CUSTOM PLAN REQUEST:');
      print('   Num Sub-Admins: $numSubAdmins');
      print('   Num Employees: $numEmployees');
      print('   Duration Days: $subscriptionDurationDays');

      final requestData = {
        'numSubAdmins': numSubAdmins,
        'numEmployees': numEmployees,
        'day': subscriptionDurationDays, // API expects 'day' parameter
      };
      print('   Request Data: $requestData');
      print('   Endpoint: ${ApiEndpoints.estimateCustomPlan}');

      final response = await _apiClient.post(
        ApiEndpoints.estimateCustomPlan,
        data: requestData,
      );

      print('\n✅ [SubscriptionRepository] ESTIMATE CUSTOM PLAN RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Timestamp: ${response.data['timestamp']}');

      final estimateData = response.data['data'];
      print('\n📦 [SubscriptionRepository] COST ESTIMATE:');
      print('   Admin Fee: ₹${estimateData['adminFee']}');
      print('   Sub-Admins Cost: ₹${estimateData['subAdminsCost']}');
      print('   Employees Cost: ₹${estimateData['employeesCost']}');
      print('   Total Cost: ₹${estimateData['totalCost']}');
      print('   Breakdown: ${estimateData['breakdown']}');

      final estimate = CostEstimate.fromJson(estimateData);
      print('\n✨ [SubscriptionRepository] Estimate calculated successfully\n');

      return estimate;
    } catch (e) {
      print('\n❌ [SubscriptionRepository] ESTIMATE CUSTOM PLAN ERROR: $e\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    try {
      print('\n📡 [SubscriptionRepository] REQUEST CUSTOM PLAN:');
      print('   Num Sub-Admins: $numSubAdmins');
      print('   Num Employees: $numEmployees');
      print('   Duration Days: $subscriptionDurationDays');

      final requestData = {
        'numSubAdmins': numSubAdmins,
        'numEmployees': numEmployees,
        'day': subscriptionDurationDays, // API expects 'day' parameter
      };
      print('   Request Data: $requestData');
      print('   Endpoint: ${ApiEndpoints.requestCustomPlan}');

      final response = await _apiClient.post(
        ApiEndpoints.requestCustomPlan,
        data: requestData,
      );

      print('\n✅ [SubscriptionRepository] REQUEST CUSTOM PLAN RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Timestamp: ${response.data['timestamp']}');
      print('   Data: ${response.data['data']}');
      print(
        '\n✨ [SubscriptionRepository] Custom plan requested successfully\n',
      );

      return response.data['data'];
    } catch (e) {
      print('\n❌ [SubscriptionRepository] REQUEST CUSTOM PLAN ERROR: $e\n');
      rethrow;
    }
  }

  Future<List<SubscriptionRequest>> getMyRequests() async {
    try {
      print('\n📡 [SubscriptionRepository] GET MY REQUESTS');
      print('   Endpoint: ${ApiEndpoints.mySubscriptionRequests}');

      final response = await _apiClient.get(
        ApiEndpoints.mySubscriptionRequests,
      );

      print('\n✅ [SubscriptionRepository] GET MY REQUESTS RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');

      final List<dynamic> data = response.data['data'] ?? [];
      final requests = data
          .map((json) => SubscriptionRequest.fromJson(json))
          .toList();

      print('\n📦 [SubscriptionRepository] Found ${requests.length} requests');
      for (var i = 0; i < requests.length; i++) {
        print('   Request ${i + 1}:');
        print('      ID: ${requests[i].id}');
        print('      Status: ${requests[i].status}');
        print('      Sub-Admins: ${requests[i].numSubAdmins}');
        print('      Employees: ${requests[i].numEmployees}');
        print('      Estimated Cost: ₹${requests[i].estimatedCost}');
      }
      print('\n✨ [SubscriptionRepository] Requests retrieved successfully\n');

      return requests;
    } catch (e) {
      print('\n❌ [SubscriptionRepository] GET MY REQUESTS ERROR: $e\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestRenewal({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    try {
      print('\n📡 [SubscriptionRepository] REQUEST RENEWAL:');
      print('   Num Sub-Admins: $numSubAdmins');
      print('   Num Employees: $numEmployees');
      print('   Duration Days: $subscriptionDurationDays');

      final requestData = {
        'numSubAdmins': numSubAdmins,
        'numEmployees': numEmployees,
        'day': subscriptionDurationDays, // API expects 'day' parameter
      };
      print('   Request Data: $requestData');
      print('   Endpoint: ${ApiEndpoints.renewalRequest}');

      final response = await _apiClient.post(
        ApiEndpoints.renewalRequest,
        data: requestData,
      );

      print('\n✅ [SubscriptionRepository] REQUEST RENEWAL RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Data: ${response.data['data']}');
      print('\n✨ [SubscriptionRepository] Renewal requested successfully\n');

      return response.data['data'];
    } catch (e) {
      print('\n❌ [SubscriptionRepository] REQUEST RENEWAL ERROR: $e\n');
      rethrow;
    }
  }

  Future<List<SubscriptionRequest>> getAllCustomRequests() async {
    try {
      print('\n📡 [SubscriptionRepository] GET ALL CUSTOM REQUESTS');
      print('   Endpoint: ${ApiEndpoints.allCustomRequests}');

      final response = await _apiClient.get(ApiEndpoints.allCustomRequests);

      print('\n✅ [SubscriptionRepository] GET ALL CUSTOM REQUESTS RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');

      final List<dynamic> data = response.data['data'] ?? [];
      final requests = data
          .map((json) => SubscriptionRequest.fromJson(json))
          .toList();

      print(
        '\n📦 [SubscriptionRepository] Found ${requests.length} pending requests',
      );
      for (var i = 0; i < requests.length; i++) {
        print('   Request ${i + 1}:');
        print('      ID: ${requests[i].id}');
        print('      Tenant ID: ${requests[i].tenantId}');
        print('      Status: ${requests[i].status}');
        print('      Sub-Admins: ${requests[i].numSubAdmins}');
        print('      Employees: ${requests[i].numEmployees}');
        print('      Duration: ${requests[i].durationDisplay}');
        print('      Estimated Cost: ₹${requests[i].estimatedCost}');
      }
      print(
        '\n✨ [SubscriptionRepository] All requests retrieved successfully\n',
      );

      return requests;
    } catch (e) {
      print('\n❌ [SubscriptionRepository] GET ALL CUSTOM REQUESTS ERROR: $e\n');
      rethrow;
    }
  }

  Future<List<RenewalRequest>> getPendingRenewalRequests() async {
    try {
      print('\n📡 [SubscriptionRepository] GET PENDING RENEWAL REQUESTS');
      print('   Endpoint: ${ApiEndpoints.pendingRenewalRequests}');

      final response = await _apiClient.get(
        ApiEndpoints.pendingRenewalRequests,
      );

      print(
        '\n✅ [SubscriptionRepository] GET PENDING RENEWAL REQUESTS RESPONSE:',
      );
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');

      final List<dynamic> data = response.data['data'] ?? [];
      final requests = data
          .map((json) => RenewalRequest.fromJson(json))
          .toList();

      print(
        '\n📦 [SubscriptionRepository] Found ${requests.length} pending renewal requests',
      );
      for (var i = 0; i < requests.length; i++) {
        print('   Renewal Request ${i + 1}:');
        print('      ID: ${requests[i].id}');
        print('      Tenant ID: ${requests[i].tenantId}');
        print('      Username: ${requests[i].username}');
        print('      Plan Name: ${requests[i].planName}');
        print('      Status: ${requests[i].status}');
        print('      Requested At: ${requests[i].requestedAt}');
      }
      print(
        '\n✨ [SubscriptionRepository] Pending renewal requests retrieved successfully\n',
      );

      return requests;
    } catch (e) {
      print(
        '\n❌ [SubscriptionRepository] GET PENDING RENEWAL REQUESTS ERROR: $e\n',
      );
      rethrow;
    }
  }
}
