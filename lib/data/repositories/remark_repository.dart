import 'dart:developer';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/data/models/leads/interaction_model.dart';

class RemarkRepository {
  final ApiClient _apiClient = ApiClient();

  /// Record lead interaction (replaces old addRemark and logCall)
  Future<String> recordInteraction({
    required String leadId,
    required LeadInteractionRequest request,
  }) async {
    try {
      log('📝 Recording lead interaction: $leadId');

      final username = PrefManager.getUsername() ?? '';

      final response = await _apiClient.post(
        ApiEndpoints.leadInteraction(leadId),
        data: request.toJson(),
        extraHeaders: {'X-User-Name': username},
      );

      log('✅ Interaction recorded successfully');
      return response.data['data'] ?? 'Interaction recorded successfully';
    } catch (e) {
      log('❌ Error recording interaction: $e');
      rethrow;
    }
  }

  /// Legacy method for backwards compatibility (deprecated)
  @Deprecated('Use recordInteraction instead')
  Future<String> addRemark(String leadId, String remark) async {
    return recordInteraction(
      leadId: leadId,
      request: LeadInteractionRequest(
        callType: CallType.newLead,
        remark: remark,
      ),
    );
  }

  /// Legacy method for backwards compatibility (deprecated)
  @Deprecated('Use recordInteraction instead')
  Future<String> logCall({
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
