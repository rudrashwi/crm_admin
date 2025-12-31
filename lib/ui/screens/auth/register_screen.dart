import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/auth_provider.dart';
import 'package:crm_admin/ui/widgets/common/custom_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  List<String> _suggestions = [];
  Timer? _debounce;

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.length > 2) {
        setState(() => _isCheckingUsername = true);
        final response = await context.read<AuthProvider>().checkUsername(value);
        if (mounted) {
          setState(() {
            _isUsernameAvailable = response?.available ?? false;
            _suggestions = response?.suggestions ?? [];
            _isCheckingUsername = false;
          });
        }
      } else {
        setState(() {
          _isUsernameAvailable = false;
          _suggestions = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Admin Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Start managing your CRM platform today'),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Username',
                hint: 'Choose a unique username',
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                suffixIcon: _isCheckingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Icon(
                        _isUsernameAvailable ? Icons.check_circle : Icons.error,
                        color: _isUsernameAvailable ? AppColors.success : AppColors.error,
                      ),
                validator: (v) => !_isUsernameAvailable ? 'Username not available' : null,
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Suggestions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _suggestions.map((s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _usernameController.text = s;
                      _onUsernameChanged(s);
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _fullNameController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Company Name',
                hint: 'Enter your company name',
                controller: _companyController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Password',
                hint: 'Create a strong password',
                controller: _passwordController,
                isPassword: true,
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 40),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return CustomButton(
                    text: 'REGISTER',
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await auth.registerAdmin(
                          username: _usernameController.text,
                          email: _emailController.text,
                          fullName: _fullNameController.text,
                          password: _passwordController.text,
                          companyName: _companyController.text,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registered Successfully! Please Login.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        } else if (auth.error != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(auth.error!),
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
