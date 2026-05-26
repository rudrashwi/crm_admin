import 'package:flutter/material.dart';
import 'package:crm_admin/data/models/leads/lead_model.dart';
import 'package:crm_admin/data/repositories/leads_repository.dart';

class LeadsProvider extends ChangeNotifier {
  final LeadsRepository _repository;

  LeadsProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<LeadModel> _leads = [];
  List<LeadModel> get leads => _leads;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchLeads() async {
    _setLoading(true);
    try {
      _leads = await _repository.getAllLeads();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createLead({
    required String customerName,
    required String contactPhone,
    String? email,
    required String requirementMessage,
  }) async {
    _setLoading(true);
    try {
      await _repository.createLead(
        customerName: customerName,
        contactPhone: contactPhone,
        email: email,
        requirementMessage: requirementMessage,
      );
      await fetchLeads();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateLead(String leadId, Map<String, dynamic> data) async {
    try {
      await _repository.updateLead(leadId, data);
      await fetchLeads();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteLead(String leadId) async {
    try {
      await _repository.deleteLead(leadId);
      _leads.removeWhere((element) => element.id == leadId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> assignLead(String leadId, String userId) async {
    try {
      await _repository.assignLead(leadId, userId);
      await fetchLeads();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> unassignLead(String leadId) async {
    try {
      await _repository.unassignLead(leadId);
      await fetchLeads();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> batchAssignLeads(List<String> leadIds, List<String> employeeIds) async {
    try {
      await _repository.batchAssignLeads(leadIds, employeeIds);
      await fetchLeads();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
