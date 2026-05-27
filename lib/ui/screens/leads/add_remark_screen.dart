import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _callDurationController = TextEditingController(text: '0');

  // Removed call log tracking variables

  // New fields for interaction API
  String _selectedCallType = CallType.newLead;
  String _selectedFollowUpStatus = 'PENDING';
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    // Do not auto-check call logs on screen load.
    // Searching call logs must be initiated manually by the user.
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _callNotesController.dispose();
    _followUpNotesController.dispose();
    _callDurationController.dispose();
    super.dispose();
  }

  /// Check if submit button should be enabled
  bool get _canSubmit {
    // Must have call notes
    final hasContent = _callNotesController.text.trim().isNotEmpty;

    // If follow-up scheduled or callback requested, must have datetime
    if (_selectedCallType == CallType.followUpScheduled ||
        _selectedCallType == CallType.callbackRequested) {
      return hasContent && _selectedDateTime != null;
    }

    return hasContent;
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

  /// Submit the interaction
  Future<void> _submitInteraction() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_canSubmit) {
      String message;
      if ((_selectedCallType == CallType.followUpScheduled ||
              _selectedCallType == CallType.callbackRequested) &&
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

    final duration = int.tryParse(_callDurationController.text.trim()) ?? 0;

    // Build interaction request
    final request = LeadInteractionRequest(
      callType: _selectedCallType,
      remark: null,
      callNotes: _callNotesController.text.trim().isNotEmpty
          ? _callNotesController.text.trim()
          : null,
      callDuration: duration > 0 ? duration : null,
      followUpStatus: (_selectedCallType == CallType.followUpScheduled ||
              _selectedCallType == CallType.callbackRequested)
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

              // Call Duration field
              const Text(
                'Call Duration (seconds)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _callDurationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 60',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Follow-up fields (conditional on call type)
              if (_selectedCallType == CallType.followUpScheduled ||
                  _selectedCallType == CallType.callbackRequested) ...[
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
                  final isEnabled = !provider.isLoading && _canSubmit;
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
