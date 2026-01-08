import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class SelectEmployeeScreen extends StatefulWidget {
  final String leadId;
  final String leadCustomerName;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;

  const SelectEmployeeScreen({
    super.key,
    required this.leadId,
    required this.leadCustomerName,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
  });

  @override
  State<SelectEmployeeScreen> createState() => _SelectEmployeeScreenState();
}

class _SelectEmployeeScreenState extends State<SelectEmployeeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Employee'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigning: ${widget.leadCustomerName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUsers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final employees = provider.users
              .where((u) => u.role == 'EMPLOYEE' && u.isActive)
              .where((u) =>
                  _searchQuery.isEmpty ||
                  u.fullName.toLowerCase().contains(_searchQuery) ||
                  u.username.toLowerCase().contains(_searchQuery) ||
                  u.email.toLowerCase().contains(_searchQuery))
              .toList();

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No employees found' : 'No matching employees',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildEmployeeCard(employees[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(UserModel employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _assignLead(employee),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 28,
                child: Text(
                  employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.alternate_email, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          employee.username,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employee.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignLead(UserModel employee) async {
    // Check if already assigned
    if (widget.assignedEmployeeId != null && widget.assignedEmployeeId!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lead Already Assigned'),
          content: Text(
            'This lead is already assigned to ${widget.assignedEmployeeName ?? "another employee"}. '
            'You need to unassign it first before assigning to someone else.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await context.read<LeadsProvider>().assignLead(
          widget.leadId,
          employee.id,
        );

    if (!mounted) return;

    // Close loading
    Navigator.pop(context);

    if (success) {
      // Close employee selection screen
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lead assigned to ${employee.fullName} (@${employee.username})'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign lead'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
