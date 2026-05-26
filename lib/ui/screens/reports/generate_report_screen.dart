import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/report_provider.dart';
import 'package:crm_admin/logic/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:device_info_plus/device_info_plus.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedReportType = 'ALL_LEADS';
  String _selectedFormat = 'EXCEL';
  String _selectedDeliveryMethod = 'DOWNLOAD';

  // Filter fields
  String? _selectedStatus;
  String? _selectedSource;
  String? _selectedEmployee;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _applyFilters = false;

  final List<Map<String, String>> _reportTypes = [
    {'value': 'ALL_LEADS', 'label': 'All Leads Report'},
    {'value': 'EMPLOYEE_PERFORMANCE', 'label': 'Employee Performance Report'},
  ];

  final List<Map<String, String>> _formats = [
    {'value': 'EXCEL', 'label': 'Excel (.xlsx)'},
    {'value': 'CSV', 'label': 'CSV (.csv)'},
  ];

  final List<String> _statuses = [
    'NEW',
    'CONTACTED',
    'QUALIFIED',
    'CONVERTED',
    'LOST',
  ];

  final List<String> _sources = [
    'WEBSITE',
    'REFERRAL',
    'SOCIAL_MEDIA',
    'ADVERTISEMENT',
    'COLD_CALL',
    'OTHER',
  ];

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final userProvider = context.watch<UserProvider>();
    final employees = userProvider.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              const Text(
                'Report Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.assessment),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Format Selection
              const Text(
                'Format',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.file_copy),
                ),
                items: _formats.map((format) {
                  return DropdownMenuItem(
                    value: format['value'],
                    child: Text(format['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Apply Filters Toggle
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Apply Filters (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Filter data by date, status, source, etc.',
                  ),
                  value: _applyFilters,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _applyFilters = value;
                    });
                  },
                ),
              ),

              // Filters Section
              if (_applyFilters) ...[
                const SizedBox(height: 24),
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ..._statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Source Filter
                DropdownButtonFormField<String>(
                  value: _selectedSource,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.source),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Sources'),
                    ),
                    ..._sources.map((source) {
                      return DropdownMenuItem(
                        value: source,
                        child: Text(source),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSource = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Employee Filter
                if (employees.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedEmployee,
                    decoration: const InputDecoration(
                      labelText: 'Assigned To',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Employees'),
                      ),
                      ...employees.map((user) {
                        return DropdownMenuItem(
                          value: user.id,
                          child: Text(user.fullName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployee = value;
                      });
                    },
                  ),

                const SizedBox(height: 16),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _startDate != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _endDate != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: reportProvider.isLoading ? null : _generateReport,
                  icon: reportProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    reportProvider.isLoading
                        ? 'Generating...'
                        : 'Generate Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Error Message
              if (reportProvider.error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppColors.error.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reportProvider.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Generated Report Info
              if (reportProvider.generatedReport != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: AppColors.success.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              reportProvider.generatedReport!.status ==
                                      'COMPLETED'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: AppColors.success,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Report Generated Successfully!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${reportProvider.generatedReport!.status}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildReportInfo(
                          'Report Type',
                          reportProvider.generatedReport!.reportType,
                        ),
                        _buildReportInfo(
                          'Format',
                          reportProvider.generatedReport!.format,
                        ),
                        if (reportProvider.generatedReport!.generatedAt != null)
                          _buildReportInfo(
                            'Generated At',
                            _formatDateTime(
                              reportProvider.generatedReport!.generatedAt!,
                            ),
                          ),
                        if (reportProvider.generatedReport!.expiresAt != null)
                          _buildReportInfo(
                            'Expires At',
                            _formatDateTime(
                              reportProvider.generatedReport!.expiresAt!,
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Download Button
                        if (reportProvider.generatedReport!.downloadUrl != null)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _downloadReport(
                                reportProvider.generatedReport!.downloadUrl!,
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Download Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) return;

    final reportProvider = context.read<ReportProvider>();

    // Build filters
    Map<String, dynamic>? filters;
    if (_applyFilters) {
      filters = {};
      if (_selectedStatus != null) filters['status'] = _selectedStatus;
      if (_selectedSource != null) filters['source'] = _selectedSource;
      if (_selectedEmployee != null) filters['assignedTo'] = _selectedEmployee;
      if (_startDate != null) {
        filters['startDate'] = DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss",
        ).format(_startDate!);
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        filters['endDate'] = DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss",
        ).format(endOfDay);
      }
    }

    final success = await reportProvider.generateReport(
      reportType: _selectedReportType,
      format: _selectedFormat,
      deliveryMethod: _selectedDeliveryMethod,
      filters: filters,
    );

    if (success && mounted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: 'Report generated successfully!'),
      );
    }
  }

  Future<void> _downloadReport(String url) async {
    try {
      // Replace localhost with production domain
      final fixedUrl = url.replaceAll(
        'http://localhost:8080',
        'https://api.rudraashwicrm.com',
      );

      // Show downloading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Downloading report...'),
              ],
            ),
          ),
        );
      }

      // Request storage permission only for Android 10-12 (API 29-32)
      // Android 13+ doesn't need permission for app-specific downloads
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Only request permission for Android 10, 11, 12 (SDK 29-32)
        if (sdkInt >= 29 && sdkInt <= 32) {
          PermissionStatus status = await Permission.storage.status;

          if (!status.isGranted) {
            status = await Permission.storage.request();
          }

          // If permission denied, show error
          if (!status.isGranted) {
            if (mounted) {
              Navigator.of(context).pop(); // Close progress dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Storage permission is required to download files',
                  ),
                  backgroundColor: AppColors.error,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => openAppSettings(),
                  ),
                ),
              );
            }
            return;
          }
        }
      }

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final extension = _selectedFormat == 'EXCEL' ? 'xlsx' : 'csv';
      final fileName = 'report_$timestamp.$extension';
      final filePath = '${directory!.path}/$fileName';

      // Download file
      final dio = Dio();
      await dio.download(
        fixedUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        // Show success dialog with file location and action to open
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                SizedBox(width: 8),
                Text('Download Complete', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report downloaded successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.folder_outlined,
                            size: 20,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'File Location:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filePath,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  final result = await OpenFilex.open(filePath);
                  if (result.type != ResultType.done && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Open File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
