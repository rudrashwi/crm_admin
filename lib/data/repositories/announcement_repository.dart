import 'package:crm_admin/core/api/api_client.dart';

class AnnouncementRepository {
  final ApiClient _apiClient;

  AnnouncementRepository(this._apiClient);

  /// Broadcast announcement to all employees
  Future<Map<String, dynamic>> broadcastToAllEmployees({
    required String title,
    required String message,
  }) async {
    print('📢 [AnnouncementRepository] Broadcasting to all employees');
    print('📢 Title: $title');
    print('📢 Message: $message');
    
    try {
      final response = await _apiClient.post(
        '/notifications/broadcast-to-employees',
        data: {
          'title': title,
          'message': message,
        },
      );
      
      print('✅ [AnnouncementRepository] Broadcast successful');
      print('✅ Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ [AnnouncementRepository] Broadcast failed: $e');
      rethrow;
    }
  }

  /// Send announcement to specific employees
  Future<Map<String, dynamic>> sendToSpecificEmployees({
    required List<String> targetUserIds,
    required String title,
    required String message,
  }) async {
    print('📢 [AnnouncementRepository] Sending to specific employees');
    print('📢 Target IDs: $targetUserIds');
    print('📢 Title: $title');
    print('📢 Message: $message');
    
    try {
      final response = await _apiClient.post(
        '/notifications/manual',
        data: {
          'targetUserIds': targetUserIds,
          'title': title,
          'message': message,
        },
      );
      
      print('✅ [AnnouncementRepository] Send successful');
      print('✅ Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ [AnnouncementRepository] Send failed: $e');
      rethrow;
    }
  }
}
