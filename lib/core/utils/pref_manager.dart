import 'package:shared_preferences/shared_preferences.dart';

class PrefManager {
  static const String _keyAccessToken = 'access_token';
  static const String _keyTenantId = 'tenant_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'role';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setAccessToken(String token) async =>
      await _prefs.setString(_keyAccessToken, token);

  static String? getAccessToken() => _prefs.getString(_keyAccessToken);

  static Future<void> setTenantId(String tenantId) async =>
      await _prefs.setString(_keyTenantId, tenantId);

  static String? getTenantId() => _prefs.getString(_keyTenantId);

  static Future<void> setUserId(String userId) async =>
      await _prefs.setString(_keyUserId, userId);

  static String? getUserId() => _prefs.getString(_keyUserId);

  static Future<void> setUsername(String username) async =>
      await _prefs.setString(_keyUsername, username);

  static String? getUsername() => _prefs.getString(_keyUsername);

  static Future<void> setRole(String role) async =>
      await _prefs.setString(_keyRole, role);

  static String? getRole() => _prefs.getString(_keyRole);

  static Future<void> clear() async => await _prefs.clear();
}
