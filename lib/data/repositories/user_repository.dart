import 'package:dio/dio.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/data/models/user_management/employee_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<UserModel>> getEmployees() async {
    try {
      final tenantId = PrefManager.getTenantId();
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID not found');
      }
      final response = await _apiClient.get(ApiEndpoints.getUsersByTenant(tenantId));
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
        extraHeaders: {
          'X-User-Id': PrefManager.getUserId(),
        },
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
        data: {
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<EmployeeDetail> getEmployeeDetails(String employeeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.employeeDetails(employeeId));
      return EmployeeDetail.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
