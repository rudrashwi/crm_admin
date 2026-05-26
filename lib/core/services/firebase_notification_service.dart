import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:crm_admin/data/repositories/notification_repository.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';
import 'package:crm_admin/ui/screens/dashboard/missed_followups_screen.dart';
import 'package:crm_admin/ui/screens/dashboard/untouched_leads_screen.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\n🔔 ========== BACKGROUND NOTIFICATION ==========');
  print('📱 Message ID: ${message.messageId}');
  print('📧 Sender ID: ${message.senderId}');
  print('⏰ Sent Time: ${message.sentTime}');
  print('\n📝 NOTIFICATION DATA:');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Android: ${message.notification?.android?.toMap()}');
  print('   Apple: ${message.notification?.apple?.toMap()}');
  print('\n💾 MESSAGE DATA:');
  print('   Keys: ${message.data.keys.toList()}');
  message.data.forEach((key, value) {
    print('   $key: $value (${value.runtimeType})');
  });
  print('\n🔥 Raw Message: ${message.toMap()}');
  print('========== END BACKGROUND NOTIFICATION ==========\n');
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
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _fcmToken;
  RemoteMessage? _pendingNotification;
  String? get fcmToken => _fcmToken;

  /// Set the notification repository for API calls
  void setRepository(NotificationRepository repository) {
    _notificationRepository = repository;
  }

  /// Set the global navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    // If there's a pending notification, handle it now
    if (_pendingNotification != null) {
      log('[INIT] Processing pending notification after navigator key set');
      _handleNotificationClick(_pendingNotification!);
      _pendingNotification = null;
    }
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
        print('\n🔔 ========== FOREGROUND NOTIFICATION ==========');
        print('📱 Message ID: ${message.messageId}');
        print('📧 Sender ID: ${message.senderId}');
        print('⏰ Sent Time: ${message.sentTime}');
        print('🔥 Category: ${message.category}');
        print('\n📝 NOTIFICATION CONTENT:');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print(
          '   Android Channel: ${message.notification?.android?.channelId}',
        );
        print(
          '   Android Priority: ${message.notification?.android?.priority}',
        );
        print('   Android Sound: ${message.notification?.android?.sound}');
        print('   Apple Badge: ${message.notification?.apple?.badge}');
        print('   Apple Sound: ${message.notification?.apple?.sound}');
        print('\n💾 MESSAGE DATA (${message.data.length} keys):');
        print('   Keys: ${message.data.keys.toList()}');
        message.data.forEach((key, value) {
          print('   📦 $key: $value');
          print('      Type: ${value.runtimeType}');
          // If value is a string that looks like JSON, try to parse it
          if (value is String &&
              (value.startsWith('{') || value.startsWith('['))) {
            try {
              final parsed = jsonDecode(value);
              print('      Parsed: $parsed');
            } catch (e) {
              print('      (Not JSON)');
            }
          }
        });
        print('\n🔥 COMPLETE MESSAGE MAP:');
        print('${jsonEncode(message.toMap())}');
        print('========== END FOREGROUND NOTIFICATION ==========\n');

        // IMMEDIATELY show notification
        _handleForegroundMessage(message);
      });

      // Handle notification clicks when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('\n👆 ========== NOTIFICATION CLICKED (BACKGROUND) ==========');
        print('📱 Message ID: ${message.messageId}');
        print('💾 Data: ${message.data}');
        print('========== END CLICK ==========\n');
        _handleNotificationClick(message);
      });

      // Check if app was opened from a notification (terminated state)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print(
          '\n🚀 ========== APP OPENED FROM NOTIFICATION (TERMINATED) ==========',
        );
        print('📱 Message ID: ${initialMessage.messageId}');
        print('💾 Data: ${initialMessage.data}');
        initialMessage.data.forEach((key, value) {
          print('   $key: $value (${value.runtimeType})');
        });
        print('========== END INITIAL MESSAGE ==========\n');
        // Store the message to be processed after navigator is ready
        _pendingNotification = initialMessage;
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

      log(
        '[PERMISSIONS] Notification permission: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('[PERMISSIONS] User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('[PERMISSIONS] User granted provisional notification permission');
      } else {
        log(
          '[PERMISSIONS] User declined or has not accepted notification permission',
        );
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
        description: 'Notifications for RudraCRM Admin app', // Channel description
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
      log(
        '[TOKEN] WARNING: Notification repository not set. Skipping token registration.',
      );
      return;
    }

    try {
      log('[TOKEN] Registering FCM token with backend...');
      print('📱 [FCM] Attempting to register device token with backend...');

      // Determine device type
      final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';

      final success = await _notificationRepository!.registerDeviceToken(
        fcmToken: token,
        deviceType: deviceType,
      );

      if (success) {
        log('[TOKEN] FCM token registered with backend successfully');
        print('✅ [FCM] Device token registered successfully!');
      } else {
        log('[TOKEN] WARNING: Failed to register FCM token with backend');
        print('⚠️ [FCM] Failed to register device token');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // This is EXPECTED on app launch before login - NOT AN ERROR
        log(
          '[TOKEN] INFO: Skipping token registration - user not authenticated yet (401). Will register after login.',
        );
        print(
          'ℹ️ [FCM] Token registration skipped - user not logged in yet (expected behavior)',
        );
        print(
          '   Token will be registered automatically after successful login.',
        );
        // Silently ignore this expected error
      } else {
        log(
          '[TOKEN] ERROR registering FCM token with backend: ${e.response?.statusCode} - ${e.message}',
        );
        print('❌ [FCM] Error registering token: ${e.response?.statusCode}');
      }
    } catch (e) {
      log('[TOKEN] ERROR registering FCM token with backend: $e');
      print('❌ [FCM] Unexpected error: $e');
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
            body:
                message.data['body'] ??
                message.data['message'] ??
                'You have a new notification',
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
      print('\n🔔 ========== SHOWING LOCAL NOTIFICATION ==========');
      final notification = message.notification;
      if (notification == null) {
        print('❌ Notification is NULL, cannot display');
        return;
      }

      final title = notification.title ?? 'RudraCRM Admin';
      final body = notification.body ?? 'You have a new message';
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      print('📝 Title: $title');
      print('📝 Body: $body');
      print('🎯 Notification ID: $notificationId');
      print('💾 Payload Data: ${message.data}');
      print('\n📦 Android Details:');
      print('   Channel: crm_notifications');
      print('   Importance: max');
      print('   Priority: max');
      print('   Sound: enabled');
      print('   Vibration: enabled');

      final androidDetails = AndroidNotificationDetails(
        'crm_notifications',
        'CRM Notifications',
        channelDescription: 'Notifications for RudraCRM Admin app',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
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
        payload: jsonEncode(message.data),
      );

      print('✅ Local notification displayed successfully');
      print('   ID: $notificationId');
      print('   Payload: ${jsonEncode(message.data)}');
      print('========== END LOCAL NOTIFICATION ==========\n');
    } catch (e, stackTrace) {
      print('❌ ERROR showing local notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Handle notification click
  void _handleNotificationClick(RemoteMessage message) {
    print('\n👆 ========== NOTIFICATION CLICKED ==========');
    print('📱 Message ID: ${message.messageId}');
    print('💾 Full Data: ${message.data}');
    print('🔑 Data Keys: ${message.data.keys.toList()}');
    print('\n📦 Detailed Data Breakdown:');

    // Log each key-value pair
    message.data.forEach((key, value) {
      print('   $key: $value (${value.runtimeType})');
    });

    if (_navigatorKey == null || _navigatorKey!.currentContext == null) {
      print('⚠️ Navigator key not available, storing notification for later');
      _pendingNotification = message;
      return;
    }

    final context = _navigatorKey!.currentContext!;
    final data = message.data;

    try {
      // CRITICAL: The 'data' field from backend contains a JSON string, parse it!
      Map<String, dynamic> parsedData = {};
      String? leadId;
      String? type;

      print('\n🔍 Parsing notification data...');

      // Check if 'data' field exists and is a string (needs parsing)
      if (data.containsKey('data') && data['data'] is String) {
        print('   Found nested "data" field as String, parsing JSON...');
        try {
          parsedData = jsonDecode(data['data']) as Map<String, dynamic>;
          print('   ✅ Parsed nested data: $parsedData');
          leadId = parsedData['leadId']?.toString();
          print('   LeadId from nested data: $leadId');
        } catch (e) {
          print('   ❌ Failed to parse nested data: $e');
        }
      }

      // Try to get type from outer data
      type =
          (data['type'] ??
                  data['notificationType'] ??
                  data['messageType'] ??
                  '')
              .toString()
              .toUpperCase();
      print('   Type from outer data: $type');

      // If leadId not found in nested data, try outer data
      if (leadId == null || leadId.isEmpty || leadId == 'null') {
        leadId =
            (data['leadId'] ??
                    data['lead_id'] ??
                    data['id'] ??
                    data['targetId'] ??
                    '')
                .toString();
        print('   LeadId from outer data: $leadId');
      }

      print('\n📌 FINAL PARSED VALUES:');
      print('   Type: "$type"');
      print('   LeadId: "$leadId"');
      print(
        '   LeadId valid: ${leadId != null && leadId.isNotEmpty && leadId != 'null'}',
      );

      // If leadId is present, always navigate to lead detail first
      if (leadId != null && leadId.isNotEmpty && leadId != 'null') {
        print('\n✅ NAVIGATING TO LEAD DETAIL SCREEN');
        print('   LeadId: $leadId');

        // Add a small delay to ensure the app is fully loaded
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_navigatorKey?.currentContext == null) {
            print('❌ Context still not available after delay');
            return;
          }

          final currentContext = _navigatorKey!.currentContext!;
          print('🚀 Pushing to LeadDetailScreen...');

          Navigator.of(currentContext).push(
            MaterialPageRoute(
              builder: (_) => LeadDetailScreen(leadId: leadId!),
            ),
          );

          print('✅ Navigation executed successfully');
        });
        print('========== END NOTIFICATION CLICK ==========\n');
        return;
      }

      // If no leadId, check notification type for other navigation
      print('\n⚠️ No valid leadId found, checking type-based navigation');
      print('   Type: $type');

      // Add a small delay to ensure the app is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_navigatorKey?.currentContext == null) {
          print('Context still not available after delay');
          return;
        }

        final currentContext = _navigatorKey!.currentContext!;

        switch (type) {
          case 'LEAD_ACTIVITY':
          case 'LEAD_ASSIGNED':
          case 'LEAD_UPDATED':
          case 'LEAD_STATUS_CHANGED':
            print('⚠️ Lead notification without leadId - Type: $type');
            break;

          case 'FOLLOW_UP_MISSED':
          case 'FOLLOW_UP_REMINDER':
            print('Navigating to MissedFollowupsScreen');
            Navigator.push(
              currentContext,
              MaterialPageRoute(builder: (_) => const MissedFollowupsScreen()),
            );
            break;

          case 'UNTOUCHED_LEAD':
            print('Navigating to UntouchedLeadsScreen');
            Navigator.push(
              currentContext,
              MaterialPageRoute(builder: (_) => const UntouchedLeadsScreen()),
            );
            break;

          case 'ANNOUNCEMENT':
          case 'BROADCAST':
            // For announcements, just show the notification, no specific navigation
            print('Announcement notification, no specific navigation');
            break;

          default:
            print('⚠️ Unknown notification type: $type');
        }
      });
      print('========== END NOTIFICATION CLICK ==========\n');
    } catch (e, stackTrace) {
      print('❌ ERROR handling notification click: $e');
      print('Stack trace: $stackTrace');
      print('========== END NOTIFICATION CLICK ==========\n');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('\n👆 ========== LOCAL NOTIFICATION TAPPED ==========');
    print('📦 Payload: ${response.payload}');

    if (_navigatorKey == null || _navigatorKey!.currentContext == null) {
      print('❌ Navigator key not available');
      return;
    }

    // Try to parse the payload as JSON
    try {
      if (response.payload != null && response.payload!.isNotEmpty) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        print('✅ Parsed payload data: $data');

        // CRITICAL: Check if there's a nested 'data' field that needs parsing
        String? leadId;

        print('\n🔍 Checking for nested data...');
        if (data.containsKey('data') && data['data'] is String) {
          print('   Found nested "data" field, parsing...');
          try {
            final nestedData = jsonDecode(data['data']) as Map<String, dynamic>;
            print('   ✅ Parsed nested data: $nestedData');
            leadId = nestedData['leadId']?.toString();
            print('   LeadId from nested: $leadId');
          } catch (e) {
            print('   ❌ Failed to parse nested data: $e');
          }
        }

        // If leadId not found in nested data, try outer data
        if (leadId == null || leadId.isEmpty || leadId == 'null') {
          leadId =
              (data['leadId'] ??
                      data['lead_id'] ??
                      data['id'] ??
                      data['targetId'] ??
                      '')
                  .toString();
          print('   LeadId from outer: $leadId');
        }

        print('\n📌 Final leadId: $leadId');

        // If we found a valid leadId, navigate to lead detail
        if (leadId != null && leadId.isNotEmpty && leadId != 'null') {
          print('✅ Valid leadId found, navigating to LeadDetailScreen');

          final context = _navigatorKey!.currentContext!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeadDetailScreen(leadId: leadId!),
            ),
          );

          print('✅ Navigation executed');
          print('========== END TAP ==========\n');
          return;
        }

        print('⚠️ No valid leadId, trying type-based navigation');
        // Create a fake RemoteMessage to reuse the same navigation logic
        final fakeMessage = RemoteMessage(data: data);
        _handleNotificationClick(fakeMessage);
      }
      print('========== END TAP ==========\n');
    } catch (e, stackTrace) {
      print('❌ Error parsing payload: $e');
      print('Stack trace: $stackTrace');

      // Fallback: try to extract leadId from string using regex
      if (response.payload != null) {
        final payload = response.payload!;
        final leadIdMatch = RegExp(
          r'"leadId"\s*:\s*"([a-f0-9-]+)"',
        ).firstMatch(payload);

        if (leadIdMatch != null) {
          final leadId = leadIdMatch.group(1);
          print('🔍 Extracted leadId via regex: $leadId');

          if (leadId != null && leadId.isNotEmpty) {
            final context = _navigatorKey!.currentContext!;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeadDetailScreen(leadId: leadId!),
              ),
            );

            print('✅ Navigation via regex successful');
          }
        } else {
          print('❌ Failed to extract leadId via regex');
        }
      }
      print('========== END TAP ==========\n');
    }
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
