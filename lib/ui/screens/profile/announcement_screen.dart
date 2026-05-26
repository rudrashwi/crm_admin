import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/data/repositories/announcement_repository.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:crm_admin/data/models/auth/user_model.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _broadcastFormKey = GlobalKey<FormState>();
  final _selectFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_broadcastFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = context.read<AnnouncementRepository>();
      final response = await repository.broadcastToAllEmployees(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      final data = response['data'] ?? 'Announcement sent successfully';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data.toString()),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send announcement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToSelected() async {
    if (!_selectFormKey.currentState!.validate()) return;

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one employee'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = context.read<AnnouncementRepository>();
      final response = await repository.sendToSpecificEmployees(
        targetUserIds: _selectedUserIds.toList(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      final data = response['data'] ?? 'Announcement sent successfully';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data.toString()),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _messageController.clear();
      _selectedUserIds.clear();
      setState(() => _selectAll = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send announcement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll(List<UserModel> eligibleUsers) {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedUserIds.addAll(eligibleUsers.map((u) => u.id));
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Announcement'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign),
              text: 'Broadcast All',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Select Members',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBroadcastTab(),
          _buildSelectMembersTab(),
        ],
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _broadcastFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast to All Employees',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This will send announcement to all employees and sub-admins',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter announcement title',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length > 20) {
                  return 'Title must be 20 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your announcement message',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendBroadcast,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Sending...' : 'Send Broadcast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectMembersTab() {
    return Consumer<UserProvider>(
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

        final eligibleUsers = provider.users
            .where((user) => user.role == 'EMPLOYEE' || user.role == 'SUB_ADMIN')
            .toList();

        if (eligibleUsers.isEmpty) {
          return const Center(
            child: Text('No employees or sub-admins found'),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with Select All
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.primary.withOpacity(0.1),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(eligibleUsers),
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedUserIds.length} selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // User List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: eligibleUsers.length,
                      itemBuilder: (context, index) {
                        final user = eligibleUsers[index];
                        final isSelected = _selectedUserIds.contains(user.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                              _selectAll = _selectedUserIds.length == eligibleUsers.length;
                            });
                          },
                          title: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.role == 'SUB_ADMIN'
                                      ? AppColors.warning.withOpacity(0.2)
                                      : AppColors.info.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role == 'SUB_ADMIN' ? 'Sub-Admin' : 'Employee',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: user.role == 'SUB_ADMIN'
                                        ? AppColors.warning
                                        : AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: isSelected ? AppColors.primary : AppColors.accent,
                            child: Text(
                              user.fullName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Form(
                key: _selectFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter announcement title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                        counterText: '',
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length > 20) {
                          return 'Title must be 20 characters or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Enter your message',
                        prefixIcon: Icon(Icons.message),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendToSelected,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Sending...' : 'Send to Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
