import 'dart:developer' as dev;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';

class ExcelUploadRepository {
  final ApiClient _apiClient;

  ExcelUploadRepository(this._apiClient);

  Future<Map<String, dynamic>> validateExcel(File file) async {
    try {
      dev.log('📡 [ExcelUploadRepository] Starting Excel validation...', name: 'EXCEL_UPLOAD');
      dev.log('📄 [ExcelUploadRepository] File path: ${file.path}', name: 'EXCEL_UPLOAD');
      dev.log('📏 [ExcelUploadRepository] File size: ${file.lengthSync()} bytes', name: 'EXCEL_UPLOAD');

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      dev.log('🚀 [ExcelUploadRepository] Sending validation request...', name: 'EXCEL_UPLOAD');
      final response = await _apiClient.post(
        ApiEndpoints.validateLeadsExcel,
        data: formData,
      );

      dev.log('✅ [ExcelUploadRepository] Validation response received', name: 'EXCEL_UPLOAD');
      dev.log('📦 [ExcelUploadRepository] Response: ${response.data}', name: 'EXCEL_UPLOAD');

      return response.data;
    } catch (e) {
      dev.log('❌ [ExcelUploadRepository] Validation error: $e', name: 'EXCEL_UPLOAD');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadExcel(File file) async {
    try {
      final tenantId = PrefManager.getTenantId();
      final userId = PrefManager.getUserId();

      dev.log('📡 [ExcelUploadRepository] Starting Excel upload...', name: 'EXCEL_UPLOAD');
      dev.log('📄 [ExcelUploadRepository] File path: ${file.path}', name: 'EXCEL_UPLOAD');
      dev.log('👤 [ExcelUploadRepository] User ID: $userId', name: 'EXCEL_UPLOAD');
      dev.log('🏢 [ExcelUploadRepository] Tenant ID: $tenantId', name: 'EXCEL_UPLOAD');

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      // Add custom headers
      final options = Options(
        headers: {
          'X-Tenant-Id': tenantId,
          'X-User-Id': userId,
        },
      );

      dev.log('🚀 [ExcelUploadRepository] Sending upload request...', name: 'EXCEL_UPLOAD');
      final response = await _apiClient.post(
        ApiEndpoints.uploadLeadsExcel,
        data: formData,
        options: options,
      );

      dev.log('✅ [ExcelUploadRepository] Upload response received', name: 'EXCEL_UPLOAD');
      dev.log('📦 [ExcelUploadRepository] Response: ${response.data}', name: 'EXCEL_UPLOAD');

      if (response.data['data'] != null) {
        final uploadId = response.data['data']['uploadId'];
        dev.log('🆔 [ExcelUploadRepository] Upload ID: $uploadId', name: 'EXCEL_UPLOAD');
      }

      return response.data;
    } catch (e) {
      dev.log('❌ [ExcelUploadRepository] Upload error: $e', name: 'EXCEL_UPLOAD');
      rethrow;
    }
  }
}
