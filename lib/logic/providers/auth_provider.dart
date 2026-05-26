import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _user;
  UserModel? get user => _user;

  String? _error;
  String? get error => _error;

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

  Future<UsernameCheckResponse?> checkUsername(String username) async {
    try {
      return await _repository.checkUsername(username);
    } catch (e) {
      _setError(_handleError(e));
      return null;
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _repository.checkUsername(username);
      return response.available;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  Future<bool> registerAdmin({
    required String username,
    required String email,
    required String fullName,
    required String mobileNumber,
    required String password,
    required String companyName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.registerAdmin(
        username: username,
        email: email,
        fullName: fullName,
        mobileNumber: mobileNumber,
        password: password,
        companyName: companyName,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_handleError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(
    String username,
    String password,
    String selectedRole,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _repository.login(username, password);
      // Allow login only for ADMIN or SUB_ADMIN role and match selected role
      if (response.user.role != 'ADMIN' && response.user.role != 'SUB_ADMIN') {
        _setError(
          'Only users with ADMIN or SUB_ADMIN role are allowed to login.',
        );
        _setLoading(false);
        return false;
      }

      // Check if selected role matches the user's actual role
      if (response.user.role != selectedRole) {
        _setError('Invalid credentials for the selected role.');
        _setLoading(false);
        return false;
      }

      _user = response.user;

      await PrefManager.setAccessToken(response.accessToken);
      await PrefManager.setTenantId(response.user.tenantId);
      await PrefManager.setUserId(response.user.id);
      await PrefManager.setUsername(response.user.username);
      await PrefManager.setRole(response.user.role);
      await PrefManager.setEmail(response.user.email);
      await PrefManager.setFullName(response.user.fullName);
      await PrefManager.setMobileNumber(response.user.mobileNumber ?? 'N/A');

      // Get app version dynamically
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Set Crashlytics user info for better crash tracking
      // Create a combined identifier: userId_username_mobile
      final userIdentifier =
          '${response.user.id}_${response.user.username}_${response.user.mobileNumber ?? "N/A"}';
      await FirebaseCrashlytics.instance.setUserIdentifier(userIdentifier);

      await FirebaseCrashlytics.instance.setCustomKey(
        'user_id',
        response.user.id,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'username',
        response.user.username,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'mobile_number',
        response.user.mobileNumber ?? 'N/A',
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'role',
        response.user.role,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'tenant_id',
        response.user.tenantId,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'app_version',
        appVersion,
      );
      print(
        '🔥 Crashlytics updated: $userIdentifier (Role: ${response.user.role}, Version: $appVersion)',
      );

      // Verify what was saved
      print('🔍 [AuthProvider] Saved userId: "${response.user.id}"');
      print(
        '🔍 [AuthProvider] Verified from storage: "${PrefManager.getUserId()}"',
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_handleError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await PrefManager.clear();
    _user = null;
    notifyListeners();
  }
}
