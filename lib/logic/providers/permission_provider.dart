import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:crm_admin/data/repositories/permission_repository.dart';

class PermissionProvider extends ChangeNotifier {
  final PermissionRepository _repository;

  PermissionProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Store permission states for each user
  final Map<String, bool> _permissionCache = {};
  
  /// Get permission status from cache for a specific user
  bool? getPermissionFromCache(String userId) {
    return _permissionCache[userId];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        return e.response?.data['message'];
      }
      return e.message ?? 'An unexpected error occurred';
    }
    return e.toString();
  }

  /// Toggle lead creation permission (grant or revoke)
  Future<bool> toggleLeadCreationPermission(String userId, bool currentStatus) async {
    print('🔄 [PermissionProvider] Toggling permission for userId: $userId, current: $currentStatus');
    _setLoading(true);
    _setError(null);
    
    try {
      Map<String, dynamic> response;
      
      if (currentStatus) {
        // Currently has permission, so revoke it
        print('🔒 [PermissionProvider] Revoking permission...');
        response = await _repository.revokeLeadCreationPermission(userId);
      } else {
        // Currently doesn't have permission, so grant it
        print('🔓 [PermissionProvider] Granting permission...');
        response = await _repository.grantLeadCreationPermission(userId);
      }
      
      if (response['success'] == true && response['data'] != null) {
        final newStatus = response['data']['canCreateLeads'] ?? false;
        _permissionCache[userId] = newStatus;
        print('✅ [PermissionProvider] Permission toggled successfully. New status: $newStatus');
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ [PermissionProvider] Error toggling permission: $e');
      _setError(_handleError(e));
      _setLoading(false);
      return false;
    }
  }

  /// Check permission status for a user
  Future<bool> checkPermission(String userId) async {
    print('🔍 [PermissionProvider] Checking permission for userId: $userId');
    
    // Return cached value if available
    if (_permissionCache.containsKey(userId)) {
      print('📦 [PermissionProvider] Returning cached permission: ${_permissionCache[userId]}');
      return _permissionCache[userId]!;
    }
    
    try {
      final canCreateLeads = await _repository.checkLeadCreationPermission(userId);
      _permissionCache[userId] = canCreateLeads;
      print('✅ [PermissionProvider] Permission checked: $canCreateLeads');
      return canCreateLeads;
    } catch (e) {
      print('❌ [PermissionProvider] Error checking permission: $e');
      return false;
    }
  }

  /// Update cached permission for a user
  void updatePermissionCache(String userId, bool canCreateLeads) {
    print('📝 [PermissionProvider] Updating cache for userId: $userId, value: $canCreateLeads');
    _permissionCache[userId] = canCreateLeads;
    notifyListeners();
  }

  /// Clear permission cache
  void clearCache() {
    print('🗑️ [PermissionProvider] Clearing permission cache');
    _permissionCache.clear();
    notifyListeners();
  }
}
