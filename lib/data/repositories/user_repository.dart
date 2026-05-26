import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/data/models/user_management/employee_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<UserModel> getProfile() async {
    try {
      print('\n📡 [UserRepository] GET PROFILE REQUEST');

      final response = await _apiClient.get(ApiEndpoints.profile);

      print('\n✅ [UserRepository] GET PROFILE RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Timestamp: ${response.data['timestamp']}');

      final userData = response.data['data'];
      print('\n📦 [UserRepository] PROFILE DATA:');
      print('   User ID: ${userData['id']}');
      print('   Username: ${userData['username']}');
      print('   Email: ${userData['email']}');
      print('   Full Name: ${userData['fullName']}');
      print('   Role: ${userData['role']}');
      print('   Tenant ID: ${userData['tenantId']}');
      print('   Company: ${userData['companyName']}');
      print('   Mobile: ${userData['mobileNumber']}');
      print('   Is Active: ${userData['isActive']}');
      print('   Can Create Leads: ${userData['canCreateLeads']}');
      print('   Created At: ${userData['createdAt']}');
      print('   Last Login: ${userData['lastLogin']}');

      if (userData['ownerSubscription'] != null) {
        print('\n💳 [UserRepository] OWNER SUBSCRIPTION:');
        print('   ID: ${userData['ownerSubscription']['id']}');
        print('   Plan Name: ${userData['ownerSubscription']['planName']}');
        print('   Status: ${userData['ownerSubscription']['status']}');
        print('   Start Date: ${userData['ownerSubscription']['startDate']}');
        print('   End Date: ${userData['ownerSubscription']['endDate']}');
        print('   Is Expired: ${userData['ownerSubscription']['isExpired']}');
        print('   Is Trial: ${userData['ownerSubscription']['isTrial']}');
      }

      if (userData['trialInfo'] != null) {
        print('\n🔄 [UserRepository] TRIAL INFO:');
        print('   Has Used Trial: ${userData['trialInfo']['hasUsedTrial']}');
        print('   Is Trial Active: ${userData['trialInfo']['isTrialActive']}');
        print('   Is Eligible: ${userData['trialInfo']['isEligible']}');
        print('   Mobile Used: ${userData['trialInfo']['mobileUsed']}');
        print('   Account Used: ${userData['trialInfo']['accountUsed']}');
        print('   Message: ${userData['trialInfo']['message']}');
      }

      final user = UserModel.fromJson(userData);
      print('\n✨ [UserRepository] Profile retrieved successfully\n');
      return user;
    } catch (e) {
      print('\n❌ [UserRepository] GET PROFILE ERROR: $e\n');
      rethrow;
    }
  }

  Future<List<UserModel>> getEmployees() async {
    try {
      final tenantId = PrefManager.getTenantId();
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID not found');
      }
      final response = await _apiClient.get(
        ApiEndpoints.getUsersByTenant(tenantId),
      );
      return (response.data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> createUser({
    required String username,
    required String email,
    required String fullName,
    required String mobileNumber,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createUser,
        extraHeaders: {'X-User-Id': PrefManager.getUserId()},
        data: {
          'username': username,
          'email': email,
          'fullName': fullName,
          'mobileNumber': mobileNumber,
          'password': password,
          'role': role,
        },
      );
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> terminateUser(String userId) async {
    try {
      await _apiClient.post(ApiEndpoints.terminateUser(userId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reactivateUser(String userId) async {
    try {
      await _apiClient.post(ApiEndpoints.reactivateUser(userId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> adminResetPassword(String userId, String newPassword) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminResetPassword(userId),
        data: {'newPassword': newPassword},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<EmployeeDetail> getEmployeeDetails(String employeeId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.employeeDetails(employeeId),
      );
      return EmployeeDetail.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
