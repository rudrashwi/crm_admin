import 'dart:developer';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/reports/report_model.dart';

class ReportRepository {
  final ApiClient _apiClient;

  ReportRepository(this._apiClient);

  /// Generate a report
  Future<ReportModel?> generateReport({
    required String reportType,
    required String format,
    required String deliveryMethod,
    Map<String, dynamic>? filters,
  }) async {
    try {
      log('📊 Generating report: $reportType');

      final response = await _apiClient.post(
        ApiEndpoints.generateReport,
        data: {
          'reportType': reportType,
          'format': format,
          'deliveryMethod': deliveryMethod,
          'filters': filters ?? {},
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return ReportModel.fromJson(data);
      } else {
        log('⚠️ Failed to generate report: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error generating report: $e');
      return null;
    }
  }

  /// Get download URL for report
  String getDownloadUrl(String reportId) {
    return '${ApiEndpoints.baseUrl}${ApiEndpoints.downloadReport(reportId)}';
  }
}
