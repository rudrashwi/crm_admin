import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  Future<bool> registerAdmin({
    required String username,
    required String email,
    required String fullName,
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

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _repository.login(username, password);
      _user = response.user;
      
      await PrefManager.setAccessToken(response.accessToken);
      await PrefManager.setTenantId(response.user.tenantId);
      await PrefManager.setUserId(response.user.id);
      await PrefManager.setUsername(response.user.username);
      await PrefManager.setRole(response.user.role);
      
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
