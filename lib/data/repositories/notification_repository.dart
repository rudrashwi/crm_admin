import 'dart:developer';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/notification/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// Fetch all notifications for the current user
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      log('[NOTIF_REPO] Fetching all notifications...');
      log('[NOTIF_REPO] API Endpoint: ${ApiEndpoints.myNotifications}');

      final response = await _apiClient.get(
        ApiEndpoints.myNotifications,
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> notificationsJson = data['data'] as List;
          log('[NOTIF_REPO] Successfully parsed ${notificationsJson.length} notifications');
          
          final notifications = notificationsJson
              .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          log('[NOTIF_REPO] Converted to ${notifications.length} NotificationModel objects');
          log('[NOTIF_REPO] Unread count: ${notifications.where((n) => !n.isRead).length}');
          log('[NOTIF_REPO] Read count: ${notifications.where((n) => n.isRead).length}');
          
          return notifications;
        } else {
          log('[NOTIF_REPO] WARNING: Response success is false or data is null');
          return [];
        }
      } else {
        log('[NOTIF_REPO] ERROR: Non-200 status code: ${response.statusCode}');
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] Unexpected error: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      log('[NOTIF_REPO] Marking notification as read...');
      log('[NOTIF_REPO] Notification ID: $notificationId');
      log('[NOTIF_REPO] API Endpoint: ${ApiEndpoints.markNotificationRead(notificationId)}');

      final response = await _apiClient.post(
        ApiEndpoints.markNotificationRead(notificationId),
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true) {
          log('[NOTIF_REPO] Successfully marked notification as read');
          return true;
        } else {
          log('[NOTIF_REPO] WARNING: Response success is false');
          log('[NOTIF_REPO] Message: ${data['message']}');
          return false;
        }
      } else {
        log('[NOTIF_REPO] ERROR: Non-200 status code: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] Unexpected error marking as read: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Register FCM device token with backend
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
  }) async {
    try {
      log('[NOTIF_REPO] Registering FCM token with backend...');
      log('[NOTIF_REPO] Device type: $deviceType');
      log('[NOTIF_REPO] FCM Token: $fcmToken');

      final response = await _apiClient.post(
        ApiEndpoints.registerDeviceToken,
        data: {'fcmToken': fcmToken, 'deviceType': deviceType},
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('[NOTIF_REPO] FCM token registered successfully');
        return true;
      } else {
        log('[NOTIF_REPO] WARNING: Failed to register FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] ERROR registering FCM token: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete a single notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      log('[NOTIF_REPO] Deleting notification...');
      log('[NOTIF_REPO] Notification ID: $notificationId');

      final response = await _apiClient.delete(
        ApiEndpoints.deleteNotification(notificationId),
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        log('[NOTIF_REPO] Notification deleted successfully');
        return true;
      } else {
        log('[NOTIF_REPO] ERROR: Failed to delete notification: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] Unexpected error deleting notification: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete multiple notifications by IDs
  Future<bool> deleteBatchNotifications(List<String> notificationIds) async {
    try {
      log('[NOTIF_REPO] Deleting batch notifications...');
      log('[NOTIF_REPO] Count: ${notificationIds.length}');

      final response = await _apiClient.delete(
        ApiEndpoints.deleteBatchNotifications,
        data: {'notificationIds': notificationIds},
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        log('[NOTIF_REPO] Batch notifications deleted successfully');
        return true;
      } else {
        log('[NOTIF_REPO] ERROR: Failed to delete batch notifications: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] Unexpected error deleting batch notifications: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    try {
      log('[NOTIF_REPO] Deleting all notifications...');

      final response = await _apiClient.delete(
        ApiEndpoints.deleteBatchNotifications,
        data: {'notificationIds': []}, // Empty array means delete all
      );

      log('[NOTIF_REPO] Response status code: ${response.statusCode}');
      log('[NOTIF_REPO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        log('[NOTIF_REPO] All notifications deleted successfully');
        return true;
      } else {
        log('[NOTIF_REPO] ERROR: Failed to delete all notifications: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_REPO] Unexpected error deleting all notifications: $e');
      log('[NOTIF_REPO] Stack trace: $stackTrace');
      return false;
    }
  }
}
