import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart' as call_log;
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/remark_provider.dart';
import 'package:crm_admin/data/models/leads/interaction_model.dart';
import 'package:intl/intl.dart';

class AddRemarkScreen extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String phoneNumber;

  const AddRemarkScreen({
    super.key,
    required this.leadId,
    required this.leadName,
    required this.phoneNumber,
  });

  @override
  State<AddRemarkScreen> createState() => _AddRemarkScreenState();
}

class _AddRemarkScreenState extends State<AddRemarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  final _callNotesController = TextEditingController();
  final _followUpNotesController = TextEditingController();

  bool _isCheckingPermission = false;
  bool _isSearchingCallLog = false;

  call_log.CallLogEntry? _foundCall;
  String? _permissionError;
  bool _callLogChecked = false;

  // New fields for interaction API
  String _selectedCallType = CallType.newLead;
  String _selectedFollowUpStatus = 'PENDING';
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    // Auto-check call logs on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchCallLog();
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _callNotesController.dispose();
    _followUpNotesController.dispose();
    super.dispose();
  }

  /// Check if submit button should be enabled
  bool get _canSubmit {
    // Must have found a call in call logs
    if (_foundCall == null) return false;

    // Must have call notes
    final hasContent = _callNotesController.text.trim().isNotEmpty;

    // If follow-up scheduled, must have datetime
    if (_selectedCallType == CallType.followUpScheduled) {
      return hasContent && _selectedDateTime != null;
    }

    return hasContent;
  }

  /// Check and request call log permission
  Future<bool> _checkAndRequestPermission() async {
    setState(() {
      _isCheckingPermission = true;
      _permissionError = null;
    });

    try {
      log('🔐 Checking call log permission');

      final status = await Permission.phone.status;

      if (status.isGranted) {
        log('✅ Permission already granted');
        setState(() {
          _isCheckingPermission = false;
        });
        return true;
      } else if (status.isDenied) {
        log('⚠️ Permission denied, requesting...');
        final result = await Permission.phone.request();

        if (result.isGranted) {
          log('✅ Permission granted after request');
          setState(() {
            _isCheckingPermission = false;
          });
          return true;
        } else {
          log('❌ Permission denied by user');
          setState(() {
            _isCheckingPermission = false;
            _permissionError =
                'Call log permission is required to log calls automatically';
          });
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        log('❌ Permission permanently denied');
        setState(() {
          _isCheckingPermission = false;
          _permissionError =
              'Permission denied. Please enable in app settings.';
        });
        return false;
      }

      setState(() {
        _isCheckingPermission = false;
      });
      return false;
    } catch (e) {
      log('❌ Error checking permission: $e');
      setState(() {
        _isCheckingPermission = false;
        _permissionError = 'Error checking permissions';
      });
      return false;
    }
  }

  /// Search for most recent call with this number
  Future<void> _searchCallLog() async {
    if (!await _checkAndRequestPermission()) {
      return;
    }

    setState(() {
      _isSearchingCallLog = true;
      _foundCall = null;
      _callLogChecked = true;
    });

    try {
      log('🔍 Searching call log for number: ${widget.phoneNumber}');

      final Iterable<call_log.CallLogEntry> entries =
          await call_log.CallLog.query(
            number: widget.phoneNumber,
            dateFrom: DateTime.now()
                .subtract(const Duration(days: 7))
                .millisecondsSinceEpoch,
            dateTo: DateTime.now().millisecondsSinceEpoch,
          );

      if (entries.isNotEmpty) {
        final mostRecent = entries.first;
        log(
          '✅ Found call: ${mostRecent.callType}, duration: ${mostRecent.duration}s',
        );

        setState(() {
          _foundCall = mostRecent;
          _isSearchingCallLog = false;
        });
      } else {
        log('⚠️ No calls found in last 7 days');
        setState(() {
          _isSearchingCallLog = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recent calls found in last 7 days'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      log('❌ Error searching call log: $e');
      setState(() {
        _isSearchingCallLog = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching call log: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show datetime picker for follow-up scheduling
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _getCallTypeForAPI(call_log.CallType? callType) {
    if (callType == null) return 'OUTGOING';
    switch (callType) {
      case call_log.CallType.incoming:
        return 'INCOMING';
      case call_log.CallType.outgoing:
        return 'OUTGOING';
      case call_log.CallType.missed:
        return 'MISSED';
      default:
        return 'OUTGOING';
    }
  }

  /// Submit the interaction
  Future<void> _submitInteraction() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_canSubmit) {
      String message;
      if (_foundCall == null) {
        message = 'Please search and find a call in call logs first';
      } else if (_selectedCallType == CallType.followUpScheduled &&
          _selectedDateTime == null) {
        message = 'Please provide call notes and schedule date/time';
      } else {
        message = 'Please provide call notes';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.warning),
      );
      return;
    }

    final provider = context.read<RemarkProvider>();
    provider.clearMessages();

    // Build interaction request
    final request = LeadInteractionRequest(
      callType: _selectedCallType,
      remark: null,
      callNotes: _callNotesController.text.trim().isNotEmpty
          ? _callNotesController.text.trim()
          : null,
      callDuration: _foundCall?.duration,
      followUpStatus: _selectedCallType == CallType.followUpScheduled
          ? _selectedFollowUpStatus
          : null,
      followUpNotes: _followUpNotesController.text.trim().isNotEmpty
          ? _followUpNotesController.text.trim()
          : null,
      scheduledDateTime: _selectedDateTime != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_selectedDateTime!)
          : null,
    );

    log('📝 Submitting interaction');
    final success = await provider.recordInteraction(
      leadId: widget.leadId,
      request: request,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to record interaction'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show success and go back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interaction recorded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Interaction',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary.withOpacity(0.9),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lead info card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.leadName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.phoneNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Call Type Dropdown
              const Text(
                'Call Type *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCallType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: CallType.all.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(CallType.getDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCallType = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Call log search button
              ElevatedButton.icon(
                onPressed: _isSearchingCallLog ? null : _searchCallLog,
                icon: _isSearchingCallLog
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isSearchingCallLog ? 'Searching...' : 'Search Call Log',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_permissionError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _permissionError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_foundCall != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Call Found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${_foundCall!.callType.toString().split('.').last.toUpperCase()}',
                      ),
                      Text('Duration: ${(_foundCall!.duration ?? 0)} seconds'),
                      Text(
                        'Time: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_foundCall!.timestamp!))}',
                      ),
                    ],
                  ),
                ),
              ],

              if (_callLogChecked && _foundCall == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No recent calls found. You can still add interaction manually.',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Call Notes field
              const Text(
                'Call Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _callNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter details about the call...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Follow-up fields (conditional on call type)
              if (_selectedCallType == CallType.followUpScheduled) ...[
                const Text(
                  'Follow-up Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Follow-up status
                DropdownButtonFormField<String>(
                  value: _selectedFollowUpStatus,
                  decoration: InputDecoration(
                    labelText: 'Follow-up Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELLED',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFollowUpStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Follow-up notes
                TextFormField(
                  controller: _followUpNotesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Follow-up Notes',
                    hintText: 'e.g., Schedule demo call, Discuss pricing...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Scheduled date/time picker
                ElevatedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDateTime == null
                        ? 'Select Date & Time *'
                        : DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(_selectedDateTime!),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDateTime == null
                        ? AppColors.warning
                        : AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              Consumer<RemarkProvider>(
                builder: (context, provider, _) {
                  final isEnabled = !provider.isLoading && _foundCall != null;
                  return ElevatedButton(
                    onPressed: isEnabled ? _submitInteraction : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Submit Interaction',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
