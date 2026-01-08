import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/logic/providers/leads_provider.dart';
import 'package:crm_admin/ui/screens/user_management/employee_detail_screen.dart';
import 'package:crm_admin/ui/screens/user_management/subadmin_detail_screen.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  State<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  String _roleFilter = 'EMPLOYEE';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProvider>().fetchUsers(),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          // Get current user info
          final currentUserRole = PrefManager.getRole();
          final currentUserId = PrefManager.getUserId();

          var users = provider.users
              .where((u) => u.role == _roleFilter)
              .toList();

          // If current user is SUB_ADMIN and viewing SUB_ADMIN tab, hide other sub-admins
          if (currentUserRole == 'SUB_ADMIN' && _roleFilter == 'SUB_ADMIN') {
            users = users.where((u) => u.id == currentUserId).toList();
          }

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            users = users.where((user) {
              final query = _searchQuery.toLowerCase();
              return user.username.toLowerCase().contains(query) ||
                  user.fullName.toLowerCase().contains(query) ||
                  user.email.toLowerCase().contains(query) ||
                  (user.mobileNumber?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return Column(
            children: [
              // Filter Chips - Hide Sub-Admins tab for sub-admin users
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _buildRoleChip('EMPLOYEE', 'Employees'),
                    // Only show Sub-Admins filter for ADMIN users
                    if (currentUserRole != 'SUB_ADMIN') ...[
                      const SizedBox(width: 8),
                      _buildRoleChip('SUB_ADMIN', 'Sub-Admins'),
                    ],
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, username, email...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              // User List
              if (users.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No users found matching "$_searchQuery"'
                          : 'No users found',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildUserCard(users[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _roleFilter == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _roleFilter = role),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isSubAdmin = user.role == 'SUB_ADMIN';
    final accent = isSubAdmin ? AppColors.warning : AppColors.primary;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _navigateToDetailScreen(user),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accent,
          radius: 24,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${user.username.isNotEmpty ? user.username : 'no-username'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                // IconButton(
                //   onPressed: () => _openEmail(user.email),
                //   icon: const Icon(Icons.email, color: AppColors.primary, size: 16),
                //   tooltip: 'Send Email',
                //   padding: EdgeInsets.zero,
                //   constraints: const BoxConstraints(),
                // ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildBadge(isSubAdmin ? 'SUB-ADMIN' : 'EMPLOYEE', accent),
                const SizedBox(width: 6),
                _buildBadge(
                  user.isActive ? 'ACTIVE' : 'INACTIVE',
                  user.isActive ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ],
        ),
        trailing: isSubAdmin
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) => _handleMenuSelection(value, user),
                itemBuilder: (context) {
                  final currentUserRole = PrefManager.getRole();
                  final isCurrentUserSubAdmin = currentUserRole == 'SUB_ADMIN';
                  // SUB_ADMIN cannot terminate/reactivate other SUB_ADMINs
                  final canModifyUser = !(isCurrentUserSubAdmin && isSubAdmin);

                  return [
                    if (!isSubAdmin)
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(Icons.assignment_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Assign Leads'),
                          ],
                        ),
                      ),
                    // const PopupMenuItem(
                    //   value: 'details',
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.info_outline, size: 18),
                    //       SizedBox(width: 8),
                    //       Text('View Details'),
                    //     ],
                    //   ),
                    // ),
                    // const PopupMenuItem(value: 'divider', enabled: false, child: Divider(height: 1)),
                    if (user.isActive && canModifyUser)
                      PopupMenuItem(
                        value: 'terminate',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.block,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSubAdmin
                                  ? 'Terminate Sub-Admin'
                                  : 'Terminate Employee',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    if (!user.isActive && canModifyUser)
                      PopupMenuItem(
                        value: 'reactivate',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSubAdmin
                                  ? 'Reactivate Sub-Admin'
                                  : 'Reactivate Employee',
                              style: const TextStyle(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                  ];
                },
              ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _navigateToDetailScreen(UserModel user) {
    if (user.role == 'SUB_ADMIN') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SubAdminDetailScreen(user: user)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmployeeDetailScreen(user: user)),
      );
    }
  }

  Future<void> _handleMenuSelection(String value, UserModel user) async {
    final provider = context.read<UserProvider>();

    if (value == 'assign') {
      await _showAssignLeadDialog(user);
    } else if (value == 'details') {
      if (!mounted) return;
      if (user.role == 'SUB_ADMIN') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubAdminDetailScreen(user: user)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmployeeDetailScreen(user: user)),
        );
      }
    } else if (value == 'terminate') {
      if (user.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user ID'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final success = await provider.terminateUser(user.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User terminated')));
      }
    } else if (value == 'reactivate') {
      if (user.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user ID'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final success = await provider.reactivateUser(user.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User reactivated')));
      }
    }
  }

  Future<void> _showAssignLeadDialog(UserModel user) async {
    if (user.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user ID'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final leadsProvider = context.read<LeadsProvider>();
    await leadsProvider.fetchLeads();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignLeadsBottomSheet(
        employeeId: user.id,
        employeeName: user.fullName,
        username: user.username,
      ),
    );
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

// Bottom Sheet for Assigning Multiple Leads
class _AssignLeadsBottomSheet extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String username;

  const _AssignLeadsBottomSheet({
    required this.employeeId,
    required this.employeeName,
    required this.username,
  });

  @override
  State<_AssignLeadsBottomSheet> createState() =>
      _AssignLeadsBottomSheetState();
}

class _AssignLeadsBottomSheetState extends State<_AssignLeadsBottomSheet> {
  final List<String> _selectedLeadIds = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Consumer<LeadsProvider>(
          builder: (context, leadsProvider, _) {
            // Filter unassigned or new leads
            final availableLeads = leadsProvider.leads
                .where(
                  (lead) => lead.status == 'NEW' || lead.status == 'UNASSIGNED',
                )
                .toList();

            // Search filter
            final filteredLeads = _searchController.text.isEmpty
                ? availableLeads
                : availableLeads
                      .where(
                        (lead) =>
                            lead.customerName.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ) ||
                            lead.contactPhone.contains(_searchController.text),
                      )
                      .toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assign Leads',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'To: ${widget.employeeName} (@${widget.username})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_selectedLeadIds.length} selected',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by name or phone...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Leads List
                  Expanded(
                    child: leadsProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredLeads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.inbox_outlined
                                      : Icons.search_off,
                                  size: 64,
                                  color: AppColors.textSecondary.withOpacity(
                                    0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No available leads to assign'
                                      : 'No leads found',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filteredLeads.length,
                            itemBuilder: (context, index) {
                              final lead = filteredLeads[index];
                              final isSelected = _selectedLeadIds.contains(
                                lead.id,
                              );

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedLeadIds.add(lead.id);
                                    } else {
                                      _selectedLeadIds.remove(lead.id);
                                    }
                                  });
                                },
                                title: Text(
                                  lead.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // const SizedBox(height: 4),
                                    // Text(
                                    //   lead.requirementMessage,
                                    //   maxLines: 1,
                                    //   overflow: TextOverflow.ellipsis,
                                    //   style: const TextStyle(fontSize: 13),
                                    // ),
                                    // const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          lead.contactPhone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            lead.status,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.info,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                activeColor: AppColors.primary,
                              );
                            },
                          ),
                  ),
                  // Bottom Action Button
                  if (!leadsProvider.isLoading && filteredLeads.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: ElevatedButton(
                          onPressed: _selectedLeadIds.isEmpty
                              ? null
                              : () => _assignLeads(leadsProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor: AppColors.textSecondary
                                .withOpacity(0.3),
                          ),
                          child: Text(
                            _selectedLeadIds.isEmpty
                                ? 'Select leads to assign'
                                : 'Assign ${_selectedLeadIds.length} Lead${_selectedLeadIds.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignLeads(LeadsProvider leadsProvider) async {
    if (_selectedLeadIds.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    for (final leadId in _selectedLeadIds) {
      final success = await leadsProvider.assignLead(leadId, widget.employeeId);
      if (success) successCount++;
    }

    if (!mounted) return;

    // Close loading
    Navigator.of(context).pop();

    // Close bottom sheet
    Navigator.of(context).pop();

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == _selectedLeadIds.length
              ? '$successCount lead${successCount > 1 ? 's' : ''} assigned successfully to @${widget.username}'
              : '$successCount of ${_selectedLeadIds.length} leads assigned',
        ),
        backgroundColor: successCount > 0 ? AppColors.success : AppColors.error,
      ),
    );
  }
}
