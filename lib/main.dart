import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/logic/providers/excel_upload_provider.dart';
import 'package:crm_admin/logic/providers/remark_provider.dart';
import 'package:crm_admin/logic/providers/report_provider.dart';
import 'package:crm_admin/logic/providers/notification_provider.dart';
import 'package:crm_admin/ui/screens/splash/splash_screen.dart';
import 'package:crm_admin/ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await PrefManager.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  final apiClient = ApiClient();

  final authRepo = AuthRepository(apiClient);
  final dashboardRepo = DashboardRepository(apiClient);
  final leadsRepo = LeadsRepository(apiClient);
  final userRepo = UserRepository(apiClient);
  final subscriptionRepo = SubscriptionRepository(apiClient);
  final excelUploadRepo = ExcelUploadRepository(apiClient);
  final reportRepo = ReportRepository(apiClient);
  final notificationRepo = NotificationRepository(apiClient);

  // Initialize Firebase Notification Service with repository
  final notificationService = FirebaseNotificationService();
  notificationService.setRepository(notificationRepo);
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardRepo)),
        ChangeNotifierProvider(create: (_) => LeadsProvider(leadsRepo)),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepo)),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(subscriptionRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ExcelUploadProvider(excelUploadRepo),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportRepo)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepo)),
        ChangeNotifierProvider(create: (_) => RemarkProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
