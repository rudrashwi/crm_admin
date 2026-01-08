import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:crm_admin/data/repositories/remark_repository.dart';
import 'package:crm_admin/data/models/leads/interaction_model.dart';

class RemarkProvider with ChangeNotifier {
  final RemarkRepository _repository = RemarkRepository();

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Record lead interaction (new unified method)
  Future<bool> recordInteraction({
    required String leadId,
    required LeadInteractionRequest request,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      log('📝 RemarkProvider: Recording interaction');
      final message = await _repository.recordInteraction(
        leadId: leadId,
        request: request,
      );
      _successMessage = message;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      log('❌ RemarkProvider: Error recording interaction - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Legacy method (deprecated - use recordInteraction)
  @Deprecated('Use recordInteraction instead')
  Future<bool> addRemark(String leadId, String remark) async {
    return recordInteraction(
      leadId: leadId,
      request: LeadInteractionRequest(
        callType: CallType.newLead,
        remark: remark,
      ),
    );
  }

  /// Legacy method (deprecated - use recordInteraction)
  @Deprecated('Use recordInteraction instead')
  Future<bool> logCall({
    required String leadId,
    required String callNotes,
    required String callType,
    required int callDuration,
  }) async {
    return recordInteraction(
      leadId: leadId,
      request: LeadInteractionRequest(
        callType: CallType.newLead,
        callNotes: callNotes,
        callDuration: callDuration,
      ),
    );
  }
}
