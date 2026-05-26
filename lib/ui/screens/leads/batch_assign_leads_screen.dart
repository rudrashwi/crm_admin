import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/data/models/leads/lead_model.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';
import 'package:crm_admin/ui/screens/leads/lead_detail_screen.dart';
import 'package:crm_admin/ui/screens/user_management/employee_detail_screen.dart';

class BatchAssignLeadsScreen extends StatefulWidget {
  const BatchAssignLeadsScreen({super.key});

  @override
  State<BatchAssignLeadsScreen> createState() => _BatchAssignLeadsScreenState();
}

class _BatchAssignLeadsScreenState extends State<BatchAssignLeadsScreen> {
  final List<LeadModel> _selectedLeads = [];
  final List<UserModel> _selectedEmployees = [];
  String?
  _lastSelectedType; // 'lead' or 'employee' to track alternating selection

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().fetchLeads();
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Assign Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Leads Column
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: AppColors.primary.withOpacity(0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Leads',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_selectedLeads.length} selected',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildLeadsList()),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey[300]),
                // Employees Column
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: AppColors.accent.withOpacity(0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Employees',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_selectedEmployees.length} selected',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildEmployeesList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status Message
          if (_selectedLeads.isNotEmpty || _selectedEmployees.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _selectedLeads.length == _selectedEmployees.length
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _selectedLeads.length == _selectedEmployees.length
                        ? Icons.check_circle_outline
                        : Icons.warning_amber,
                    color: _selectedLeads.length == _selectedEmployees.length
                        ? AppColors.success
                        : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLeads.length == _selectedEmployees.length
                          ? 'Ready to assign: ${_selectedLeads.length} lead(s) to ${_selectedEmployees.length} employee(s)'
                          : 'Number of leads (${_selectedLeads.length}) must equal number of employees (${_selectedEmployees.length})',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            _selectedLeads.length == _selectedEmployees.length
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    onPressed:
                        _selectedLeads.isEmpty && _selectedEmployees.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedLeads.clear();
                              _selectedEmployees.clear();
                              _lastSelectedType = null; // Reset selection type
                            });
                          },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.batch_prediction),
                    label: const Text('Assign Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        _selectedLeads.isEmpty ||
                            _selectedEmployees.isEmpty ||
                            _selectedLeads.length != _selectedEmployees.length
                        ? null
                        : _performBatchAssign,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList() {
    return Consumer<LeadsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final unassignedLeads = provider.leads
            .where(
              (lead) =>
                  lead.assignedEmployeeId == null ||
                  lead.assignedEmployeeId!.isEmpty,
            )
            .toList();

        if (unassignedLeads.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
                SizedBox(height: 16),
                Text(
                  'All leads are assigned!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            4,
            4,
            4,
            4 + MediaQuery.of(context).viewPadding.bottom,
          ),
          itemCount: unassignedLeads.length,
          itemBuilder: (context, index) {
            final lead = unassignedLeads[index];
            final isSelected = _selectedLeads.any((l) => l.id == lead.id);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Enforce alternating selection rule
                  if (!isSelected && _lastSelectedType == 'lead') {
                    // Show warning - cannot select two leads in a row
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select an employee next. Alternating selection: Lead → Employee → Lead',
                        ),
                        backgroundColor: AppColors.warning,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    if (isSelected) {
                      _selectedLeads.removeWhere((l) => l.id == lead.id);
                      // Update last selected type based on what's left
                      if (_selectedLeads.isEmpty &&
                          _selectedEmployees.isEmpty) {
                        _lastSelectedType = null;
                      } else if (_selectedEmployees.isNotEmpty) {
                        _lastSelectedType = 'employee';
                      }
                    } else {
                      _selectedLeads.add(lead);
                      _lastSelectedType = 'lead';
                    }
                  });
                },
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadDetailScreen(leadId: lead.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(
                    lead.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Contact: " + lead.contactPhone,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          // IconButton(
                          //   onPressed: () => _makeCall(lead.contactPhone),
                          //   icon: const Icon(Icons.call, color: AppColors.success, size: 18),
                          //   tooltip: 'Call',
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(),
                          // ),
                          // const SizedBox(width: 8),
                          // IconButton(
                          //   onPressed: () => _openWhatsApp(lead.contactPhone),
                          //   icon: const FaIcon(
                          //     FontAwesomeIcons.whatsapp,
                          //     color: Color(0xFF25D366),
                          //     size: 18,
                          //   ),
                          //   tooltip: 'WhatsApp',
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(),
                          // ),
                        ],
                      ),
                      Text(
                        "Message: " + lead.requirementMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                ),
                // secondary: Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: AppColors.info.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(4),
                //   ),
                //   child: Text(
                //     lead.status,
                //     style: const TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.bold),
                //   ),
                // ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeesList() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final employees = provider.users
            .where((u) => u.role == 'EMPLOYEE' && u.isActive)
            .toList();

        if (employees.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'No active employees found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            4,
            4,
            4,
            4 + MediaQuery.of(context).viewPadding.bottom,
          ),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            final isSelected = _selectedEmployees.any(
              (e) => e.id == employee.id,
            );

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: isSelected
                  ? AppColors.accent.withOpacity(0.08)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Enforce alternating selection rule
                  if (!isSelected && _lastSelectedType == 'employee') {
                    // Show warning - cannot select two employees in a row
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select a lead next. Alternating selection: Employee → Lead → Employee',
                        ),
                        backgroundColor: AppColors.warning,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    if (isSelected) {
                      _selectedEmployees.removeWhere(
                        (e) => e.id == employee.id,
                      );
                      // Update last selected type based on what's left
                      if (_selectedLeads.isEmpty &&
                          _selectedEmployees.isEmpty) {
                        _lastSelectedType = null;
                      } else if (_selectedLeads.isNotEmpty) {
                        _lastSelectedType = 'lead';
                      }
                    } else {
                      _selectedEmployees.add(employee);
                      _lastSelectedType = 'employee';
                    }
                  });
                },
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailScreen(user: employee),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(
                    employee.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? AppColors.accent : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Id - ${employee.username}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee.email,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          // IconButton(
                          //   onPressed: () => _openEmail(employee.email),
                          //   icon: const Icon(Icons.email, color: AppColors.primary, size: 18),
                          //   tooltip: 'Send Email',
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(),
                          // ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.accent,
                          size: 24,
                        )
                      : null,
                ),
                // secondary: CircleAvatar(
                //   backgroundColor: AppColors.accent,
                //   child: Text(
                //     employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
                //     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                //   ),
                // ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Batch Assignment Guide',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'How Batch Assignment Works:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpStep(
                      '1',
                      'Sequential Assignment',
                      'Leads are assigned to employees in the order they are selected.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpStep(
                      '2',
                      'First Lead → First Employee',
                      'The 1st selected lead will be assigned to the 1st selected employee.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpStep(
                      '3',
                      'Second Lead → Second Employee',
                      'The 2nd selected lead will be assigned to the 2nd selected employee.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpStep(
                      '4',
                      'And So On...',
                      'This pattern continues for all selected leads and employees.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Important: You must select an equal number of leads and employees for batch assignment to work.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Viewing Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpStep(
                      '👆',
                      'Tap to Select',
                      'Tap on any lead or employee card to select/deselect them for batch assignment.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpStep(
                      '👇',
                      'Long Press for Details',
                      'Long press on any lead or employee card to view their complete details.',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Got It', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHelpStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performBatchAssign() async {
    // Confirm before assignment
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Batch Assignment'),
        content: Text(
          'You are about to assign ${_selectedLeads.length} lead(s) to ${_selectedEmployees.length} employee(s).\n\n'
          'Assignment will be done sequentially in the order of selection.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Prepare data
    final leadIds = _selectedLeads.map((l) => l.id).toList();
    final employeeIds = _selectedEmployees.map((e) => e.id).toList();

    // Call API
    final success = await context.read<LeadsProvider>().batchAssignLeads(
      leadIds,
      employeeIds,
    );

    if (!mounted) return;

    // Close loading
    Navigator.pop(context);

    if (success) {
      setState(() {
        _selectedLeads.clear();
        _selectedEmployees.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch assignment completed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign leads. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _makeCall(String phone) async {
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: ${phone}')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final uri = Uri.parse('https://wa.me/$cleanPhone');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Make sure it is installed.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openEmail(String email) async {
    try {
      final uri = Uri(scheme: 'mailto', path: email);
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email app. Make sure one is installed.',
            ),
          ),
        );
      }
    }
  }
}
