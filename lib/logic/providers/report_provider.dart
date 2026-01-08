import 'package:flutter/foundation.dart';
import 'package:crm_admin/data/models/reports/report_model.dart';
import 'package:crm_admin/data/repositories/report_repository.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider(this._repository);

  bool _isLoading = false;
  String? _error;
  ReportModel? _generatedReport;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ReportModel? get generatedReport => _generatedReport;

  /// Generate report
  Future<bool> generateReport({
    required String reportType,
    required String format,
    required String deliveryMethod,
    Map<String, dynamic>? filters,
  }) async {
    _isLoading = true;
    _error = null;
    _generatedReport = null;
    notifyListeners();

    try {
      final report = await _repository.generateReport(
        reportType: reportType,
        format: format,
        deliveryMethod: deliveryMethod,
        filters: filters,
      );

      if (report != null) {
        _generatedReport = report;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to generate report';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider
  void reset() {
    _generatedReport = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
