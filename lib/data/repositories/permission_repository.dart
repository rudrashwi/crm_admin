import 'package:dio/dio.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';

class PermissionRepository {
  final ApiClient _apiClient;

  PermissionRepository(this._apiClient);

  /// Grant lead creation permission to an employee
  Future<Map<String, dynamic>> grantLeadCreationPermission(String userId) async {
    try {
      print('🔑 [PermissionRepository] Granting lead creation permission for userId: $userId');
      final response = await _apiClient.post(
        '/users/$userId/permissions/grant-lead-creation',
      );
      print('✅ [PermissionRepository] Grant permission response: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ [PermissionRepository] Error granting permission: $e');
      rethrow;
    }
  }

  /// Revoke lead creation permission from an employee
  Future<Map<String, dynamic>> revokeLeadCreationPermission(String userId) async {
    try {
      print('🔑 [PermissionRepository] Revoking lead creation permission for userId: $userId');
      final adminId = PrefManager.getUserId();
      print('🔍 [PermissionRepository] Admin ID: $adminId');
      
      final response = await _apiClient.post(
        '/users/$userId/permissions/revoke-lead-creation',
        extraHeaders: {
          'X-User-Id': adminId,
        },
      );
      print('✅ [PermissionRepository] Revoke permission response: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ [PermissionRepository] Error revoking permission: $e');
      rethrow;
    }
  }

  /// Check user permissions (get canCreateLeads status)
  Future<bool> checkLeadCreationPermission(String userId) async {
    try {
      print('🔍 [PermissionRepository] Checking lead creation permission for userId: $userId');
      final response = await _apiClient.get(
        '/users/$userId/permissions',
      );
      print('✅ [PermissionRepository] Check permission response: ${response.data}');
      
      final canCreateLeads = response.data['data']['canCreateLeads'] ?? false;
      print('🔑 [PermissionRepository] canCreateLeads: $canCreateLeads');
      
      return canCreateLeads;
    } catch (e) {
      print('❌ [PermissionRepository] Error checking permission: $e');
      rethrow;
    }
  }
}
