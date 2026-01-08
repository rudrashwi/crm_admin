import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:crm_admin/data/models/notification/notification_model.dart';
import 'package:crm_admin/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get readCount => _notifications.where((n) => n.isRead).length;
  int get totalCount => _notifications.length;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  /// Fetch all notifications
  Future<void> fetchNotifications() async {
    try {
      log('[NOTIF_PROVIDER] Starting to fetch notifications...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      log('[NOTIF_PROVIDER] Calling repository.getMyNotifications()...');
      final fetchedNotifications = await _repository.getMyNotifications();
      
      log('[NOTIF_PROVIDER] Received ${fetchedNotifications.length} notifications');
      _notifications = fetchedNotifications;
      _error = null;

      log('[NOTIF_PROVIDER] Notification stats:');
      log('[NOTIF_PROVIDER] - Total: $totalCount');
      log('[NOTIF_PROVIDER] - Unread: $unreadCount');
      log('[NOTIF_PROVIDER] - Read: $readCount');

      // Log notification types breakdown
      final typeBreakdown = <String, int>{};
      for (final notif in _notifications) {
        typeBreakdown[notif.type] = (typeBreakdown[notif.type] ?? 0) + 1;
      }
      log('[NOTIF_PROVIDER] Type breakdown: $typeBreakdown');

    } catch (e, stackTrace) {
      log('[NOTIF_PROVIDER] ERROR fetching notifications: $e');
      log('[NOTIF_PROVIDER] Stack trace: $stackTrace');
      _error = e.toString();
      _notifications = [];
    } finally {
      _isLoading = false;
      log('[NOTIF_PROVIDER] Fetch complete. isLoading = false');
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      log('[NOTIF_PROVIDER] Marking notification as read...');
      log('[NOTIF_PROVIDER] Notification ID: $notificationId');

      final success = await _repository.markAsRead(notificationId);
      
      if (success) {
        log('[NOTIF_PROVIDER] Successfully marked as read in backend');
        
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          log('[NOTIF_PROVIDER] Updating local notification state at index $index');
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          
          log('[NOTIF_PROVIDER] Updated notification stats:');
          log('[NOTIF_PROVIDER] - Total: $totalCount');
          log('[NOTIF_PROVIDER] - Unread: $unreadCount');
          log('[NOTIF_PROVIDER] - Read: $readCount');
          
          notifyListeners();
        } else {
          log('[NOTIF_PROVIDER] WARNING: Notification not found in local list');
        }
        
        return true;
      } else {
        log('[NOTIF_PROVIDER] Failed to mark as read in backend');
        return false;
      }
    } catch (e, stackTrace) {
      log('[NOTIF_PROVIDER] ERROR marking as read: $e');
      log('[NOTIF_PROVIDER] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      log('[NOTIF_PROVIDER] Marking all notifications as read...');
      log('[NOTIF_PROVIDER] Unread count before: $unreadCount');

      final unreadNotifs = unreadNotifications;
      log('[NOTIF_PROVIDER] Processing ${unreadNotifs.length} unread notifications');

      int successCount = 0;
      int failureCount = 0;

      for (final notification in unreadNotifs) {
        log('[NOTIF_PROVIDER] Marking notification ${notification.id} as read...');
        final success = await markAsRead(notification.id);
        
        if (success) {
          successCount++;
          log('[NOTIF_PROVIDER] Successfully marked ${notification.id}');
        } else {
          failureCount++;
          log('[NOTIF_PROVIDER] Failed to mark ${notification.id}');
        }
      }

      log('[NOTIF_PROVIDER] Mark all complete:');
      log('[NOTIF_PROVIDER] - Success: $successCount');
      log('[NOTIF_PROVIDER] - Failures: $failureCount');
      log('[NOTIF_PROVIDER] - Unread count after: $unreadCount');

    } catch (e, stackTrace) {
      log('[NOTIF_PROVIDER] ERROR marking all as read: $e');
      log('[NOTIF_PROVIDER] Stack trace: $stackTrace');
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    log('[NOTIF_PROVIDER] Refreshing notifications...');
    await fetchNotifications();
  }

  /// Clear error
  void clearError() {
    log('[NOTIF_PROVIDER] Clearing error state');
    _error = null;
    notifyListeners();
  }
}
