import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/data/repositories/auth_repository.dart';
import 'package:crm_admin/data/repositories/dashboard_repository.dart';
import 'package:crm_admin/data/repositories/leads_repository.dart';
import 'package:crm_admin/data/repositories/user_repository.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/logic/providers/dashboard_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/ui/screens/auth/login_screen.dart';
import 'package:crm_admin/ui/screens/home/home_screen.dart';
import 'package:crm_admin/ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefManager.init();

  final apiClient = ApiClient();
  
  final authRepo = AuthRepository(apiClient);
  final dashboardRepo = DashboardRepository(apiClient);
  final leadsRepo = LeadsRepository(apiClient);
  final userRepo = UserRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardRepo)),
        ChangeNotifierProvider(create: (_) => LeadsProvider(leadsRepo)),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final token = PrefManager.getAccessToken();

    return MaterialApp(
      title: 'CRM Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: token != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
