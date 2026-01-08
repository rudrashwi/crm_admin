import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/data/models/user_management/employee_model.dart';
import 'package:crm_admin/data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;

  UserProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  EmployeeDetail? _selectedEmployee;
  EmployeeDetail? get selectedEmployee => _selectedEmployee;

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

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      _users = await _repository.getEmployees();
      _error = null;
    } catch (e) {
      _error = _handleError(e);
    }
    _setLoading(false);
  }

  Future<bool> createUser({
    required String username,
    required String email,
    required String fullName,
    required String mobileNumber,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _repository.createUser(
        username: username,
        email: email,
        fullName: fullName,
        mobileNumber: mobileNumber,
        password: password,
        role: role,
      );
      await fetchUsers();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> terminateUser(String userId) async {
    try {
      await _repository.terminateUser(userId);
      await fetchUsers();
      // Optimistically update selected employee active state so UI reacts immediately
      if (_selectedEmployee != null) {
        _selectedEmployee = _selectedEmployee!.copyWith(isActive: false);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _handleError(e);
      return false;
    }
  }

  Future<bool> reactivateUser(String userId) async {
    try {
      await _repository.reactivateUser(userId);
      await fetchUsers();
      // Optimistically update selected employee active state so UI reacts immediately
      if (_selectedEmployee != null) {
        _selectedEmployee = _selectedEmployee!.copyWith(isActive: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _handleError(e);
      return false;
    }
  }

  Future<void> fetchEmployeeDetails(String employeeId) async {
    _setLoading(true);
    try {
      _selectedEmployee = await _repository.getEmployeeDetails(employeeId);
      _error = null;
    } catch (e) {
      _error = _handleError(e);
    }
    _setLoading(false);
  }

  Future<bool> resetPassword(String userId, String newPassword) async {
    _setLoading(true);
    try {
      await _repository.adminResetPassword(userId, newPassword);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _handleError(e);
      _setLoading(false);
      return false;
    }
  }
}
