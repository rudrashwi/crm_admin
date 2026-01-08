import 'package:dio/dio.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UsernameCheckResponse> checkUsername(String username) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.checkUsername,
        queryParameters: {'username': username},
      );
      return UsernameCheckResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> registerAdmin({
    required String username,
    required String email,
    required String fullName,
    required String mobileNumber,
    required String password,
    required String companyName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerAdmin,
        data: {
          'username': username,
          'email': email,
          'fullName': fullName,
          'mobileNumber': mobileNumber,
          'password': password,
          'companyName': companyName,
        },
      );
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      print('🔍 [AuthRepository] Login response data: ${response.data}');
      final loginResponse = LoginResponse.fromJson(response.data['data']);
      print('🔍 [AuthRepository] Parsed userId: "${loginResponse.user.id}"');
      print('🔍 [AuthRepository] Parsed username: "${loginResponse.user.username}"');
      print('🔍 [AuthRepository] Parsed role: "${loginResponse.user.role}"');
      return loginResponse;
    } catch (e) {
      rethrow;
    }
  }
}
