import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:crm_admin/data/repositories/notification_repository.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('[BACKGROUND] Message received: ${message.messageId}');
  log('[BACKGROUND] Title: ${message.notification?.title}');
  log('[BACKGROUND] Body: ${message.notification?.body}');
  log('[BACKGROUND] Data: ${message.data}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationRepository? _notificationRepository;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Set the notification repository for API calls
  void setRepository(NotificationRepository repository) {
    _notificationRepository = repository;
  }

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    try {
      log('[INIT] Initializing Firebase Notification Service...');

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications FIRST
      await _initializeLocalNotifications();

      // Create notification channel BEFORE listening to messages
      await _createNotificationChannel();

      // CRITICAL: Set foreground notification presentation options for iOS
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      await _getFCMToken();

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('[TOKEN] FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _registerTokenWithBackend(newToken);
      });

      // Handle foreground messages - CRITICAL for showing notifications when app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('[FOREGROUND] ========== FOREGROUND MESSAGE RECEIVED ==========');
        log('[FOREGROUND] Message ID: ${message.messageId}');
        log('[FOREGROUND] Notification title: ${message.notification?.title}');
        log('[FOREGROUND] Notification body: ${message.notification?.body}');
        log('[FOREGROUND] Data: ${message.data}');
        
        // IMMEDIATELY show notification
        _handleForegroundMessage(message);
      });

      // Handle notification clicks when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Check if app was opened from a notification (terminated state)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log('[INIT] App opened from notification (terminated state)');
        _handleNotificationClick(initialMessage);
      }

      log('[INIT] Firebase Notification Service initialized successfully');
      log('[INIT] Foreground notifications are ENABLED');
    } catch (e) {
      log('[INIT] ERROR: Error initializing Firebase Notification Service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      log('[PERMISSIONS] Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('[PERMISSIONS] User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('[PERMISSIONS] User granted provisional notification permission');
      } else {
        log('[PERMISSIONS] User declined or has not accepted notification permission');
      }
    } catch (e) {
      log('[PERMISSIONS] ERROR: $e');
    }
  }

  /// Initialize Flutter Local Notifications for displaying notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      log('[LOCAL_NOTIF] Local notifications initialized');
    } catch (e) {
      log('[LOCAL_NOTIF] ERROR: $e');
    }
  }

  /// Create notification channel for Android with sound and vibration
  Future<void> _createNotificationChannel() async {
    try {
      final androidChannel = AndroidNotificationChannel(
        'crm_notifications', // Channel ID
        'CRM Notifications', // Channel name
        description: 'Notifications for CRM Admin app', // Channel description
        importance: Importance.max, // Changed to max for heads-up notifications
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([
          0,
          1000,
          500,
          1000,
        ]), // Vibration pattern
        sound: const RawResourceAndroidNotificationSound('notification'),
        showBadge: true,
        enableLights: true, // Enable LED indicator
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      log('[CHANNEL] Notification channel created');
    } catch (e) {
      log('[CHANNEL] ERROR: $e');
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      log('[TOKEN] FCM Token: $_fcmToken');

      // Register token with backend
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      log('[TOKEN] ERROR: $e');
    }
  }

  /// Register FCM token with backend server
  Future<void> _registerTokenWithBackend(String token) async {
    if (_notificationRepository == null) {
      log('[TOKEN] WARNING: Notification repository not set. Skipping token registration.');
      return;
    }

    try {
      log('[TOKEN] Registering FCM token with backend...');

      // Determine device type
      final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';

      final success = await _notificationRepository!.registerDeviceToken(
        fcmToken: token,
        deviceType: deviceType,
      );

      if (success) {
        log('[TOKEN] FCM token registered with backend successfully');
      } else {
        log('[TOKEN] WARNING: Failed to register FCM token with backend');
      }
    } catch (e) {
      log('[TOKEN] ERROR registering FCM token with backend: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    log('[HANDLER] ===== HANDLE FOREGROUND MESSAGE CALLED =====');
    log('[HANDLER] Message ID: ${message.messageId}');
    log('[HANDLER] Has notification: ${message.notification != null}');
    
    if (message.notification != null) {
      log('[HANDLER] Title: ${message.notification!.title}');
      log('[HANDLER] Body: ${message.notification!.body}');
    }
    log('[HANDLER] Data: ${message.data}');

    // CRITICAL: ALWAYS display notification when app is in foreground
    try {
      if (message.notification != null) {
        log('[HANDLER] Notification found! Calling _showLocalNotification...');
        _showLocalNotification(message);
      } else {
        log('[HANDLER] No notification in message, checking data...');
        // If there's no notification payload but there's data, create a notification
        if (message.data.isNotEmpty) {
          log('[HANDLER] Creating notification from data...');
          final fakeNotification = RemoteNotification(
            title: message.data['title'] ?? 'New Message',
            body: message.data['body'] ?? message.data['message'] ?? 'You have a new notification',
          );
          final fakeMessage = RemoteMessage(
            notification: fakeNotification,
            data: message.data,
          );
          _showLocalNotification(fakeMessage);
        } else {
          log('[HANDLER] No notification and no data to show');
        }
      }
    } catch (e) {
      log('[HANDLER] ERROR in _handleForegroundMessage: $e');
      log('[HANDLER] Stack trace: ${StackTrace.current}');
    }
  }

  /// Display local notification with sound and vibration
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) {
        log('[SHOW] Notification is NULL, cannot display');
        return;
      }

      final title = notification.title ?? 'CRM Admin';
      final body = notification.body ?? 'You have a new message';
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      log('[SHOW] Preparing to show notification - Title: $title, Body: $body');

      final androidDetails = AndroidNotificationDetails(
        'crm_notifications',
        'CRM Notifications',
        channelDescription: 'Notifications for CRM Admin app',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
        ticker: title,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        channelShowBadge: true,
        onlyAlertOnce: false,
        autoCancel: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: message.data.toString(),
      );

      log('[SHOW] NOTIFICATION DISPLAYED SUCCESSFULLY! ID: $notificationId');
    } catch (e, stack) {
      log('[SHOW] CRITICAL ERROR showing notification: $e');
      log('[SHOW] Stack trace: $stack');
    }
  }

  /// Handle notification click
  void _handleNotificationClick(RemoteMessage message) {
    log('[CLICK] Notification clicked: ${message.messageId}');
    log('[CLICK] Data: ${message.data}');

    // TODO: Navigate to specific screen based on notification data
    // Example:
    // if (message.data.containsKey('screen')) {
    //   final screen = message.data['screen'];
    //   // Navigate to screen
    // }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    log('[TAP] Local notification tapped');
    log('[TAP] Payload: ${response.payload}');

    // TODO: Handle navigation based on payload
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('[TOPIC] Subscribed to topic: $topic');
    } catch (e) {
      log('[TOPIC] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('[TOPIC] Unsubscribed from topic: $topic');
    } catch (e) {
      log('[TOPIC] Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('[TOKEN] FCM token deleted');
    } catch (e) {
      log('[TOKEN] Error deleting token: $e');
    }
  }
}
