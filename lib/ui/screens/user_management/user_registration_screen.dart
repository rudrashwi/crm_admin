import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/logic/providers/subscription_provider.dart';
import 'package:crm_admin/ui/screens/user_management/view_users_screen.dart';
import 'package:crm_admin/ui/widgets/common/custom_widgets.dart';
import 'dart:async';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'EMPLOYEE';
  bool _isAdmin = true;

  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    final role = PrefManager.getRole() ?? 'ADMIN';
    _isAdmin = role == 'ADMIN';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final username = _usernameController.text;

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (mounted) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameMessage = null;
        _isCheckingUsername = false;
      });
    }

    // Validate format first
    if (username.isEmpty) {
      return;
    }

    if (username.length < 3) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameMessage = 'Username must be at least 3 characters';
        });
      }
      return;
    }

    // Check format: only alphanumeric and underscore, no spaces or special characters
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameMessage = 'Only letters, numbers and underscore allowed';
        });
      }
      return;
    }

    // Set debounce timer to check availability after 500ms of no typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsername(username);
    });
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
        _usernameMessage = 'Username must be at least 3 characters';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameMessage = 'Verifying username...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final isAvailable = await authProvider.checkUsernameAvailability(
        username,
      );

      if (mounted && _usernameController.text == username) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
          _usernameMessage = isAvailable
              ? '✓ Username is available'
              : '✗ Username is already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameMessage = 'Error checking username';
          _isUsernameAvailable = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User/Sub-Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Add employees or sub-admins to your team'),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Username',
                    hint: 'Enter username (letters, numbers and _ only)',
                    controller: _usernameController,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length < 3) return 'Minimum 3 characters';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v))
                        return 'Only letters, numbers and underscore allowed';
                      if (_isUsernameAvailable != true)
                        return 'Username not available';
                      return null;
                    },
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 24,
                          )
                        : _isUsernameAvailable == false
                        ? const Icon(
                            Icons.cancel,
                            color: AppColors.error,
                            size: 24,
                          )
                        : null,
                  ),
                  if (_usernameMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        children: [
                          if (_isUsernameAvailable == true)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16,
                            )
                          else if (_isUsernameAvailable == false)
                            const Icon(
                              Icons.cancel,
                              color: AppColors.error,
                              size: 16,
                            )
                          else if (_isCheckingUsername)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _usernameMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _isCheckingUsername
                                    ? AppColors.textSecondary
                                    : _isUsernameAvailable == true
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _fullNameController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                hint: 'Enter email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                    return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Mobile Number',
                hint: 'Enter 10-digit mobile number',
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v.length != 10) return 'Must be exactly 10 digits';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                    return 'Only numbers allowed';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Role',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                items: _isAdmin
                    ? const [
                        DropdownMenuItem(
                          value: 'EMPLOYEE',
                          child: Text('Employee'),
                        ),
                        DropdownMenuItem(
                          value: 'SUB_ADMIN',
                          child: Text('Sub-Admin'),
                        ),
                      ]
                    : const [
                        DropdownMenuItem(
                          value: 'EMPLOYEE',
                          child: Text('Employee'),
                        ),
                      ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              if (!_isAdmin)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'ℹ️ Sub-admins can only create employee accounts',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Password',
                hint: 'Enter password (min 8 characters)',
                controller: _passwordController,
                isPassword: true,
                validator: (v) =>
                    v!.length < 8 ? 'Minimum 8 characters required' : null,
              ),
              const SizedBox(height: 40),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return CustomButton(
                    text: 'CREATE USER',
                    isLoading: userProvider.isLoading,
                    onPressed: () async {
                      // Check if username is verified
                      if (_isUsernameAvailable != true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please verify username first'),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        // Check subscription limits before creating user
                        final userId = PrefManager.getUserId();
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User ID not found'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final subscriptionProvider = context
                            .read<SubscriptionProvider>();
                        await subscriptionProvider.fetchUserSubscription(
                          userId,
                        );

                        final subscription = subscriptionProvider.subscription;
                        if (subscription == null || subscription.expired) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No active subscription found. Please subscribe first.',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 4),
                            ),
                          );
                          return;
                        }

                        // Check limits based on role
                        final remaining = subscription.remaining;
                        if (remaining == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to verify subscription limits',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        if (_selectedRole == 'SUB_ADMIN' &&
                            remaining.subAdmins <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sub-Admin limit reached! You have ${subscription.usage?.subAdmins ?? 0}/${subscription.limits?.subAdmins ?? 0} sub-admins. Please upgrade your subscription.',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          return;
                        }

                        if (_selectedRole == 'EMPLOYEE' &&
                            remaining.employees <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Employee limit reached! You have ${subscription.usage?.employees ?? 0}/${subscription.limits?.employees ?? 0} employees. Please upgrade your subscription.',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          return;
                        }

                        // All validations passed, create user
                        final success = await userProvider.createUser(
                          username: _usernameController.text,
                          email: _emailController.text,
                          fullName: _fullNameController.text,
                          mobileNumber: _mobileNumberController.text,
                          password: _passwordController.text,
                          role: _selectedRole,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User created successfully!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          // Clear the form after successful creation
                          _formKey.currentState!.reset();
                          _usernameController.clear();
                          _emailController.clear();
                          _fullNameController.clear();
                          _mobileNumberController.clear();
                          _passwordController.clear();
                          setState(() {
                            _selectedRole = 'EMPLOYEE';
                            _isUsernameAvailable = null;
                            _usernameMessage = '';
                          });
                        } else if (userProvider.error != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(userProvider.error!),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
