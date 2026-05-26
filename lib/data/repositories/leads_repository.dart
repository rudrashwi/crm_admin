import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/leads/lead_model.dart';

class LeadsRepository {
  final ApiClient _apiClient;

  LeadsRepository(this._apiClient);

  Future<List<LeadModel>> getAllLeads() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getAllLeads);
      return (response.data['data'] as List)
          .map((e) => LeadModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LeadModel> createLead({
    required String customerName,
    required String contactPhone,
    required String email,
    required String requirementMessage,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createLead,
        data: {
          'customerName': customerName,
          'contactPhone': contactPhone,
          'email': email,
          'requirementMessage': requirementMessage,
        },
      );
      return LeadModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLead(String leadId) async {
    try {
      await _apiClient.delete(ApiEndpoints.deleteLead(leadId));
    } catch (e) {
      rethrow;
    }
  }

  Future<LeadModel> updateLead(String leadId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateLead(leadId),
        data: data,
      );
      return LeadModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignLead(String leadId, String userId) async {
    try {
      await _apiClient.post(ApiEndpoints.assignLead(leadId, userId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unassignLead(String leadId) async {
    try {
      print('📡 [LeadsRepository] Calling unassign API for lead: $leadId');
      await _apiClient.post(ApiEndpoints.unassignLead(leadId));
      print('✅ [LeadsRepository] Unassign API call successful');
    } catch (e) {
      print('❌ [LeadsRepository] Unassign API call failed: $e');
      rethrow;
    }
  }

  Future<LeadModel> transferLead(String leadId, String newEmployeeId) async {
    try {
      print('📡 [LeadsRepository] Calling transfer API');
      print('   Endpoint: ${ApiEndpoints.transferLead(leadId)}');
      print('   Payload: {newEmployeeId: $newEmployeeId}');
      
      final response = await _apiClient.post(
        ApiEndpoints.transferLead(leadId),
        data: {
          'newEmployeeId': newEmployeeId,
        },
      );
      
      print('✅ [LeadsRepository] Transfer API call successful');
      print('   Response: ${response.data}');
      
      return LeadModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ [LeadsRepository] Transfer API call failed: $e');
      rethrow;
    }
  }

  Future<void> batchAssignLeads(List<String> leadIds, List<String> employeeIds) async {
    try {
      await _apiClient.post(
        ApiEndpoints.batchAssignLeads,
        data: {
          'leadIds': leadIds,
          'employeeIds': employeeIds,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update lead status
  Future<LeadModel> updateLeadStatus(String leadId, String status) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateLead(leadId),
        data: {
          'status': status,
        },
      );
      return LeadModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
