import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/ui/widgets/common/custom_widgets.dart';
import 'package:crm_admin/ui/screens/auth/register_screen.dart';
import 'package:crm_admin/ui/screens/home/home_screen.dart';
import 'package:crm_admin/ui/screens/splash/splash_screen.dart';
import 'package:crm_admin/ui/screens/subscription/subscription_pricing_screen.dart';
import 'package:crm_admin/ui/screens/subscription/pending_subscription_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'ADMIN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.width * 0.3,
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
                            size: 50,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'RUDRACRM ADMIN',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Professional Management Suite',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to manage your business',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          label: 'Username',
                          hint: 'Enter your username',
                          controller: _usernameController,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          isPassword: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Login As',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('Administrator'),
                                subtitle: const Text(
                                  'Full access to all features',
                                  style: TextStyle(fontSize: 12),
                                ),
                                value: 'ADMIN',
                                groupValue: _selectedRole,
                                activeColor: AppColors.primary,
                                onChanged: (value) =>
                                    setState(() => _selectedRole = value!),
                              ),
                              const Divider(height: 1),
                              RadioListTile<String>(
                                title: const Text('Sub-Admin'),
                                subtitle: const Text(
                                  'Limited administrative access',
                                  style: TextStyle(fontSize: 12),
                                ),
                                value: 'SUB_ADMIN',
                                groupValue: _selectedRole,
                                activeColor: AppColors.accent,
                                onChanged: (value) =>
                                    setState(() => _selectedRole = value!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return CustomButton(
                              text: 'LOGIN',
                              isLoading: auth.isLoading,
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  dev.log(
                                    '🔐 [LoginScreen] Attempting login...',
                                    name: 'LOGIN',
                                  );
                                  final success = await auth.login(
                                    _usernameController.text,
                                    _passwordController.text,
                                    _selectedRole,
                                  );

                                  if (success && mounted) {
                                    dev.log(
                                      '✅ [LoginScreen] Login successful',
                                      name: 'LOGIN',
                                    );
                                    final role = PrefManager.getRole();
                                    dev.log(
                                      '👤 [LoginScreen] User role: $role',
                                      name: 'LOGIN',
                                    );

                                    // Navigate to splash screen which will handle routing based on role and subscription
                                    dev.log(
                                      '➡️ [LoginScreen] Navigating to splash for role check...',
                                      name: 'LOGIN',
                                    );
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SplashScreen(),
                                      ),
                                    );
                                  } else if (auth.error != null && mounted) {
                                    dev.log(
                                      '❌ [LoginScreen] Login failed: ${auth.error}',
                                      name: 'LOGIN',
                                    );
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Login Failed'),
                                        content: Text(auth.error!),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              child: const Text(
                                'Register Now',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
