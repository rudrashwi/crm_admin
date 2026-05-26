import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/ui/screens/leads/view_leads_screen.dart';
import 'package:crm_admin/ui/widgets/common/custom_widgets.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _requirementController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Clear form when going back
          _nameController.clear();
          _phoneController.clear();
          _emailController.clear();
          _requirementController.clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add New Lead')),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lead Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Capture new business opportunities'),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Customer Name',
                  hint: 'Enter customer name',
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Contact Phone',
                  hint: 'Enter 10-digit phone number',
                  controller: _phoneController,
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
                CustomTextField(
                  label: 'Email Address (Optional)',
                  hint: 'Enter email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null &&
                        v.isNotEmpty &&
                        !RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(v)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Requirement Message',
                  hint: 'Describe the requirements',
                  controller: _requirementController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 40),
                Consumer<LeadsProvider>(
                  builder: (context, provider, _) {
                    return CustomButton(
                      text: 'CREATE LEAD',
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await provider.createLead(
                            customerName: _nameController.text,
                            contactPhone: _phoneController.text,
                            email: _emailController.text,
                            requirementMessage: _requirementController.text,
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lead created successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            // Clear the form after successful creation
                            _formKey.currentState!.reset();
                            _nameController.clear();
                            _phoneController.clear();
                            _emailController.clear();
                            _requirementController.clear();
                          } else if (provider.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.error!),
                                backgroundColor: AppColors.error,
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
      ),
    );
  }
}
