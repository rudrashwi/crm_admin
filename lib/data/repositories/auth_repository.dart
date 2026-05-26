import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UsernameCheckResponse> checkUsername(String username) async {
    try {
      print('\n📡 [AuthRepository] CHECK USERNAME REQUEST:');
      print('   Username: $username');

      final response = await _apiClient.get(
        ApiEndpoints.checkUsername,
        queryParameters: {'username': username},
      );

      print('\n✅ [AuthRepository] CHECK USERNAME RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Available: ${response.data['data']['available']}');
      print('   Message: ${response.data['data']['message']}');
      if (response.data['data']['suggestions'] != null) {
        print('   Suggestions: ${response.data['data']['suggestions']}');
      }
      print('');

      return UsernameCheckResponse.fromJson(response.data['data']);
    } catch (e) {
      print('\n❌ [AuthRepository] CHECK USERNAME ERROR: $e\n');
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
      print('\n📡 [AuthRepository] REGISTER ADMIN REQUEST:');
      print('   Username: $username');
      print('   Email: $email');
      print('   Full Name: $fullName');
      print('   Mobile: $mobileNumber');
      print('   Company: $companyName');

      final requestData = {
        'username': username,
        'email': email,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'password': password,
        'companyName': companyName,
      };
      print('   Request Data: $requestData');

      final response = await _apiClient.post(
        ApiEndpoints.registerAdmin,
        data: requestData,
      );

      print('\n✅ [AuthRepository] REGISTER ADMIN RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');
      print('   Timestamp: ${response.data['timestamp']}');

      final userData = response.data['data'];
      print('\n📦 [AuthRepository] USER DATA:');
      print('   User ID: ${userData['id']}');
      print('   Username: ${userData['username']}');
      print('   Email: ${userData['email']}');
      print('   Role: ${userData['role']}');
      print('   Tenant ID: ${userData['tenantId']}');
      print('   Company: ${userData['companyName']}');
      print('   Mobile: ${userData['mobileNumber']}');
      print('   Is Active: ${userData['isActive']}');

      if (userData['trialInfo'] != null) {
        print('\n🔄 [AuthRepository] TRIAL INFO:');
        print('   Has Used Trial: ${userData['trialInfo']['hasUsedTrial']}');
        print('   Is Eligible: ${userData['trialInfo']['isEligible']}');
        print('   Message: ${userData['trialInfo']['message']}');
        if (userData['trialInfo']['reason'] != null) {
          print('   Reason: ${userData['trialInfo']['reason']}');
        }
      }

      final user = UserModel.fromJson(userData);
      print(
        '\n✨ [AuthRepository] Registration successful for: ${user.username}\n',
      );
      return user;
    } catch (e) {
      print('\n❌ [AuthRepository] REGISTER ADMIN ERROR: $e\n');
      rethrow;
    }
  }

  Future<LoginResponse> login(String username, String password) async {
    try {
      print('\n📡 [AuthRepository] LOGIN REQUEST:');
      print('   Username: $username');

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      print('\n✅ [AuthRepository] LOGIN RESPONSE:');
      print('   Full Response: ${response.data}');
      print('   Success: ${response.data['success']}');
      print('   Message: ${response.data['message']}');

      final loginResponse = LoginResponse.fromJson(response.data['data']);
      print('\n📦 [AuthRepository] LOGIN DATA:');
      print('   User ID: ${loginResponse.user.id}');
      print('   Username: ${loginResponse.user.username}');
      print('   Role: ${loginResponse.user.role}');
      print('   Tenant ID: ${loginResponse.user.tenantId}');
      print('   Company: ${loginResponse.user.companyName}');
      print(
        '   Access Token: ${loginResponse.accessToken.substring(0, 20)}...',
      );
      print('   Token Type: ${loginResponse.tokenType}');
      print('   Expires In: ${loginResponse.expiresIn} seconds');
      print('\n✨ [AuthRepository] Login successful\n');

      return loginResponse;
    } catch (e) {
      print('\n❌ [AuthRepository] LOGIN ERROR: $e\n');
      rethrow;
    }
  }
}
