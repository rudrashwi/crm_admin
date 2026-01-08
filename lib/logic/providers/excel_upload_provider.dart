import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:crm_admin/data/repositories/excel_upload_repository.dart';

class ExcelUploadProvider extends ChangeNotifier {
  final ExcelUploadRepository _repository;

  ExcelUploadProvider(this._repository);

  bool _isValidating = false;
  bool get isValidating => _isValidating;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isValid = false;
  bool get isValid => _isValid;

  List<String> _validationErrors = [];
  List<String> get validationErrors => _validationErrors;

  String? _uploadId;
  String? get uploadId => _uploadId;

  String? _error;
  String? get error => _error;

  void _setValidating(bool value) {
    dev.log('🔄 [ExcelUploadProvider] Validating: $value', name: 'EXCEL_UPLOAD');
    _isValidating = value;
    notifyListeners();
  }

  void _setUploading(bool value) {
    dev.log('🔄 [ExcelUploadProvider] Uploading: $value', name: 'EXCEL_UPLOAD');
    _isUploading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    dev.log('⚠️ [ExcelUploadProvider] Error: $value', name: 'EXCEL_UPLOAD');
    _error = value;
    notifyListeners();
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        return e.response?.data['message'];
      }
      return e.message ?? 'An unexpected error occurred';
    }
    return e.toString();
  }

  void reset() {
    dev.log('🔄 [ExcelUploadProvider] Resetting state...', name: 'EXCEL_UPLOAD');
    _isValid = false;
    _validationErrors = [];
    _uploadId = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> validateExcel(File file) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
    dev.log('🚀 [ExcelUploadProvider] Starting validation...', name: 'EXCEL_UPLOAD');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
    
    _setValidating(true);
    _isValid = false;
    _validationErrors = [];
    _error = null;

    try {
      final response = await _repository.validateExcel(file);
      
      dev.log('📊 [ExcelUploadProvider] Processing validation response...', name: 'EXCEL_UPLOAD');
      
      final success = response['success'] ?? false;
      final message = response['message'] ?? '';
      final data = response['data'];

      dev.log('✓ Success: $success', name: 'EXCEL_UPLOAD');
      dev.log('💬 Message: $message', name: 'EXCEL_UPLOAD');

      if (success && data != null && data['isValid'] == true) {
        _isValid = true;
        dev.log('✅ [ExcelUploadProvider] File is VALID', name: 'EXCEL_UPLOAD');
        dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
        _setValidating(false);
        return true;
      } else {
        _isValid = false;
        
        // Extract errors from response
        if (data != null && data['errors'] != null) {
          _validationErrors = List<String>.from(data['errors']);
          dev.log('❌ [ExcelUploadProvider] Validation failed with errors:', name: 'EXCEL_UPLOAD');
          for (var i = 0; i < _validationErrors.length; i++) {
            dev.log('   ${i + 1}. ${_validationErrors[i]}', name: 'EXCEL_UPLOAD');
          }
        } else {
          _validationErrors = [message];
          dev.log('❌ [ExcelUploadProvider] Validation failed: $message', name: 'EXCEL_UPLOAD');
        }
        
        _error = message;
        dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
        _setValidating(false);
        return false;
      }
    } catch (e) {
      dev.log('❌ [ExcelUploadProvider] Validation exception: $e', name: 'EXCEL_UPLOAD');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
      _error = _handleError(e);
      _isValid = false;
      _validationErrors = [_error!];
      _setValidating(false);
      return false;
    }
  }

  Future<bool> uploadExcel(File file) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
    dev.log('🚀 [ExcelUploadProvider] Starting upload...', name: 'EXCEL_UPLOAD');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
    
    _setUploading(true);
    _uploadId = null;
    _error = null;

    try {
      final response = await _repository.uploadExcel(file);
      
      dev.log('📊 [ExcelUploadProvider] Processing upload response...', name: 'EXCEL_UPLOAD');
      
      final success = response['success'] ?? false;
      final message = response['message'] ?? '';
      final data = response['data'];

      dev.log('✓ Success: $success', name: 'EXCEL_UPLOAD');
      dev.log('💬 Message: $message', name: 'EXCEL_UPLOAD');

      if (success && data != null) {
        _uploadId = data['uploadId'];
        final progressMessage = data['message'];
        
        dev.log('✅ [ExcelUploadProvider] Upload initiated successfully', name: 'EXCEL_UPLOAD');
        dev.log('🆔 Upload ID: $_uploadId', name: 'EXCEL_UPLOAD');
        dev.log('📢 Message: $progressMessage', name: 'EXCEL_UPLOAD');
        dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
        _setUploading(false);
        return true;
      } else {
        dev.log('❌ [ExcelUploadProvider] Upload failed: $message', name: 'EXCEL_UPLOAD');
        dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
        _error = message;
        _setUploading(false);
        return false;
      }
    } catch (e) {
      dev.log('❌ [ExcelUploadProvider] Upload exception: $e', name: 'EXCEL_UPLOAD');
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'EXCEL_UPLOAD');
      _error = _handleError(e);
      _setUploading(false);
      return false;
    }
  }
}
