import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/ui/screens/auth/login_screen.dart';
import 'package:crm_admin/ui/screens/home/home_screen.dart';
import 'package:crm_admin/ui/screens/subscription/subscription_pricing_screen.dart';
import 'package:crm_admin/ui/screens/subscription/pending_subscription_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    dev.log('🚀 [SplashScreen] Initializing app...', name: 'SPLASH');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
    dev.log('📱 STEP 1: Checking Login Status', name: 'SPLASH');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');

    // Small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final token = PrefManager.getAccessToken();
    final role = PrefManager.getRole();

    dev.log('🔐 [SplashScreen] Token exists: ${token != null}', name: 'SPLASH');
    dev.log('👤 [SplashScreen] User role: $role', name: 'SPLASH');

    // STEP 1: Check if user is logged in
    if (token == null) {
      dev.log(
        '❌ [SplashScreen] Not logged in - navigating to Login Screen',
        name: 'SPLASH',
      );
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    dev.log('✅ [SplashScreen] User is logged in', name: 'SPLASH');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
    dev.log('📱 STEP 2: Checking User Role', name: 'SPLASH');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');

    // STEP 2: Token exists - check role
    if (role == 'EMPLOYEE') {
      dev.log(
        '✅ [SplashScreen] Role: EMPLOYEE (No subscription check needed)',
        name: 'SPLASH',
      );
      dev.log('➡️ [SplashScreen] Navigating to Dashboard', name: 'SPLASH');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    // STEP 3: ADMIN or SUB_ADMIN - check subscription
    if (role == 'ADMIN' || role == 'SUB_ADMIN') {
      dev.log('✅ [SplashScreen] Role: $role', name: 'SPLASH');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      dev.log('📱 STEP 3: Checking Subscription Status', name: 'SPLASH');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      await _checkSubscriptionAndNavigate(role!);
    } else {
      // Unknown role or no role - go to login
      dev.log(
        '⚠️ [SplashScreen] Unknown/No role - navigating to Login Screen',
        name: 'SPLASH',
      );
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _checkSubscriptionAndNavigate(String role) async {
    try {
      final userId = PrefManager.getUserId();
      dev.log(
        '🔍 [SplashScreen] Retrieved userId from storage: "$userId"',
        name: 'SPLASH',
      );

      if (userId == null || userId.isEmpty) {
        dev.log(
          '❌ [SplashScreen] No user ID found - navigating to Login',
          name: 'SPLASH',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final subProvider = context.read<SubscriptionProvider>();
      dev.log(
        '📡 [SplashScreen] Fetching subscription for user: $userId',
        name: 'SPLASH',
      );
      await subProvider.fetchUserSubscription(userId);

      if (!mounted) return;

      final subscription = subProvider.subscription;

      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      dev.log(
        '📱 DECISION: Routing based on subscription status',
        name: 'SPLASH',
      );
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');

      // No subscription found
      if (subscription == null) {
        dev.log('💰 [SplashScreen] Subscription Status: NONE', name: 'SPLASH');

        if (role == 'SUB_ADMIN') {
          dev.log(
            '⏳ [SplashScreen] ✓ Login: YES (SUB_ADMIN) ❌ Subscription: NOT FOUND',
            name: 'SPLASH',
          );
          dev.log(
            '➡️ [SplashScreen] Navigating to PENDING SCREEN (SUB_ADMIN cannot request)',
            name: 'SPLASH',
          );
          dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PendingSubscriptionScreen(),
            ),
          );
        } else {
          dev.log(
            '💰 [SplashScreen] ✓ Login: YES (ADMIN) ❌ Subscription: NOT FOUND',
            name: 'SPLASH',
          );
          dev.log(
            '➡️ [SplashScreen] Navigating to PRICING SCREEN',
            name: 'SPLASH',
          );
          dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SubscriptionPricingScreen(),
            ),
          );
        }
        return;
      }

      // Log subscription details
      dev.log(
        '📋 [SplashScreen] Plan: ${subscription.planName}',
        name: 'SPLASH',
      );
      dev.log(
        '📋 [SplashScreen] Start: ${subscription.startDate}, End: ${subscription.endDate}',
        name: 'SPLASH',
      );
      dev.log(
        '📋 [SplashScreen] Days Remaining: ${subscription.daysRemaining}',
        name: 'SPLASH',
      );
      dev.log(
        '📋 [SplashScreen] Expired: ${subscription.expired}',
        name: 'SPLASH',
      );

      // Check if subscription is expired or active
      if (subscription.isActive && !subscription.expired) {
        dev.log('✅ [SplashScreen] Subscription Status: ACTIVE', name: 'SPLASH');
        dev.log(
          '✅ [SplashScreen] Remaining Time: ${subscription.remainingTime}',
          name: 'SPLASH',
        );
        dev.log(
          '🎉 [SplashScreen] ✓ Login: YES ✓ Subscription: ACTIVE',
          name: 'SPLASH',
        );
        dev.log('➡️ [SplashScreen] Navigating to DASHBOARD', name: 'SPLASH');
        dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Subscription expired
        dev.log(
          '❌ [SplashScreen] Subscription Status: EXPIRED',
          name: 'SPLASH',
        );

        if (role == 'SUB_ADMIN') {
          dev.log(
            '⏳ [SplashScreen] ✓ Login: YES (SUB_ADMIN) ❌ Subscription: EXPIRED',
            name: 'SPLASH',
          );
          dev.log(
            '➡️ [SplashScreen] Navigating to PENDING SCREEN',
            name: 'SPLASH',
          );
          dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PendingSubscriptionScreen(),
            ),
          );
        } else {
          dev.log(
            '❌ [SplashScreen] ✓ Login: YES (ADMIN) ❌ Subscription: EXPIRED',
            name: 'SPLASH',
          );
          dev.log(
            '➡️ [SplashScreen] Navigating to PRICING SCREEN',
            name: 'SPLASH',
          );
          dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SubscriptionPricingScreen(),
            ),
          );
        }
      }
    } catch (e) {
      dev.log('❌ [SplashScreen] Subscription check error: $e', name: 'SPLASH');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'SPLASH');
      if (!mounted) return;

      // On error, show error dialog and go to login
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Subscription Check Failed'),
          content: Text(
            'Unable to verify subscription status: $e\n\nPlease login again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: Colors.blue,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CRM ADMIN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Professional Management Suite',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
