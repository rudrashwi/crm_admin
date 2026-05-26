import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/core/services/firebase_notification_service.dart';
import 'package:crm_admin/data/repositories/auth_repository.dart';
import 'package:crm_admin/data/repositories/dashboard_repository.dart';
import 'package:crm_admin/data/repositories/leads_repository.dart';
import 'package:crm_admin/data/repositories/user_repository.dart';
import 'package:crm_admin/data/repositories/subscription_repository.dart';
import 'package:crm_admin/data/repositories/excel_upload_repository.dart';
import 'package:crm_admin/data/repositories/notification_repository.dart';
import 'package:crm_admin/data/repositories/report_repository.dart';
import 'package:crm_admin/data/repositories/permission_repository.dart';
import 'package:crm_admin/data/repositories/announcement_repository.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/logic/providers/excel_upload_provider.dart';
import 'package:crm_admin/logic/providers/remark_provider.dart';
import 'package:crm_admin/logic/providers/report_provider.dart';
import 'package:crm_admin/logic/providers/notification_provider.dart';
import 'package:crm_admin/logic/providers/permission_provider.dart';
import 'package:crm_admin/ui/screens/splash/splash_screen.dart';
import 'package:crm_admin/ui/theme/app_theme.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Wrap everything in error handling zone to ensure same zone is used throughout
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize SharedPreferences
      await PrefManager.init();

      // Initialize Firebase
      await Firebase.initializeApp();

      // Configure Firebase Crashlytics to automatically catch all errors
      FlutterError.onError = (errorDetails) {
        // Send Flutter framework errors to Crashlytics
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
          reason: 'Uncaught async error',
        );
        return true;
      };

      // Enable automatic collection of crash reports
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Get app version dynamically from package info
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Set user identifier for Crashlytics (if user is logged in)
      final userId = PrefManager.getUserId();
      final username = PrefManager.getUsername();
      final role = PrefManager.getRole();
      final mobileNumber = PrefManager.getMobileNumber();

      if (userId != null && userId.isNotEmpty) {
        // Create a combined identifier: userId_username_mobile
        final userIdentifier =
            '${userId}_${username ?? "unknown"}_${mobileNumber ?? "unknown"}';
        await FirebaseCrashlytics.instance.setUserIdentifier(userIdentifier);

        // Add custom keys for better tracking in Firebase Console
        await FirebaseCrashlytics.instance.setCustomKey('user_id', userId);
        await FirebaseCrashlytics.instance.setCustomKey(
          'username',
          username ?? 'unknown',
        );
        await FirebaseCrashlytics.instance.setCustomKey(
          'mobile_number',
          mobileNumber ?? 'unknown',
        );
        await FirebaseCrashlytics.instance.setCustomKey(
          'role',
          role ?? 'unknown',
        );
        await FirebaseCrashlytics.instance.setCustomKey(
          'app_version',
          appVersion,
        );

        print(
          '🔥 Crashlytics User Set: $userIdentifier (Role: $role, Version: $appVersion)',
        );
      } else {
        // Even if not logged in, set custom keys for tracking
        await FirebaseCrashlytics.instance.setCustomKey(
          'app_version',
          appVersion,
        );
        await FirebaseCrashlytics.instance.setCustomKey(
          'login_status',
          'not_logged_in',
        );
        print(
          '🔥 Crashlytics: Anonymous user tracking enabled (Version: $appVersion)',
        );
      }

      final apiClient = ApiClient();

      final authRepo = AuthRepository(apiClient);
      final dashboardRepo = DashboardRepository(apiClient);
      final leadsRepo = LeadsRepository(apiClient);
      final userRepo = UserRepository(apiClient);
      final subscriptionRepo = SubscriptionRepository(apiClient);
      final excelUploadRepo = ExcelUploadRepository(apiClient);
      final reportRepo = ReportRepository(apiClient);
      final notificationRepo = NotificationRepository(apiClient);
      final permissionRepo = PermissionRepository(apiClient);
      final announcementRepo = AnnouncementRepository(apiClient);

      // Initialize Firebase Notification Service with repository
      final notificationService = FirebaseNotificationService();
      notificationService.setRepository(notificationRepo);
      notificationService.setNavigatorKey(navigatorKey);
      await notificationService.initialize();

      // Run the app
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
            ChangeNotifierProvider(
              create: (_) => DashboardProvider(dashboardRepo),
            ),
            ChangeNotifierProvider(create: (_) => LeadsProvider(leadsRepo)),
            ChangeNotifierProvider(create: (_) => UserProvider(userRepo)),
            ChangeNotifierProvider(
              create: (_) => SubscriptionProvider(subscriptionRepo),
            ),
            ChangeNotifierProvider(
              create: (_) => ExcelUploadProvider(excelUploadRepo),
            ),
            ChangeNotifierProvider(create: (_) => ReportProvider(reportRepo)),
            ChangeNotifierProvider(
              create: (_) => NotificationProvider(notificationRepo),
            ),
            ChangeNotifierProvider(
              create: (_) => PermissionProvider(permissionRepo),
            ),
            Provider.value(value: announcementRepo),
            ChangeNotifierProvider(create: (_) => RemarkProvider()),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      // Catch errors that occur outside of the Flutter framework
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Unhandled zone error',
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RudraCRM Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
