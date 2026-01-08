import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/logic/providers/excel_upload_provider.dart';

class UploadExcelScreen extends StatefulWidget {
  const UploadExcelScreen({super.key});

  @override
  State<UploadExcelScreen> createState() => _UploadExcelScreenState();
}

class _UploadExcelScreenState extends State<UploadExcelScreen> {
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcelUploadProvider>().reset();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
        
        // Reset provider state when new file is selected
        if (mounted) {
          context.read<ExcelUploadProvider>().reset();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _validateFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await context.read<ExcelUploadProvider>().validateExcel(_selectedFile!);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ File is valid! You can now upload.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Validation failed. Check errors below.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: Text('Upload $_fileName to import leads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context.read<ExcelUploadProvider>().uploadExcel(_selectedFile!);
    
    if (!mounted) return;
    
    if (success) {
      final uploadId = context.read<ExcelUploadProvider>().uploadId;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 32),
              SizedBox(width: 12),
              Text('Upload Started'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Excel file upload has been initiated successfully!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload ID:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      uploadId ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The leads are being processed in the background. You will be notified once the import is complete.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${context.read<ExcelUploadProvider>().error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Leads Excel'),
        elevation: 0,
      ),
      body: Consumer<ExcelUploadProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Your Excel file must contain these headers:\n   • Customer Name\n   • Phone\n   • Email\n   • Requirement',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Click "Select File" to choose your Excel file',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. Click "Validate" to check if your file is correct',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '4. Once validated, click "Upload" to import leads',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // File Selection Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 64,
                        color: _selectedFile != null ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? 'File Selected' : 'No File Selected',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _fileName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: provider.isValidating || provider.isUploading ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Select File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Validation Errors
                if (provider.validationErrors.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error),
                            SizedBox(width: 8),
                            Text(
                              'Validation Errors',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...provider.validationErrors.map((error) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.error)),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Success Message
                if (provider.isValid && !provider.isValidating) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: AppColors.success),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'File validation passed! Ready to upload.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedFile == null || provider.isValidating || provider.isUploading
                            ? null
                            : _validateFile,
                        icon: provider.isValidating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified),
                        label: Text(provider.isValidating ? 'Validating...' : 'Validate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedFile == null || !provider.isValid || provider.isUploading
                            ? null
                            : _uploadFile,
                        icon: provider.isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(provider.isUploading ? 'Uploading...' : 'Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
