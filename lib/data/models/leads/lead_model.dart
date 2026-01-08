import 'package:crm_admin/data/models/leads/interaction_model.dart';

class LeadModel {
  final String id;
  final String tenantId;
  final String customerName;
  final String contactPhone;
  final String email;
  final String requirementMessage;
  final String status;
  final String source;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? assignedEmployeeMobile;
  final String createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;
  final String? nextFollowUp;
  final List<TimelineEvent>? timeline;
  final List<CallRecord>? calls;
  final List<NoteRecord>? notes;
  final List<StatusHistoryRecord>? statusHistory;
  final List<FollowUpRecord>? followUps;

  LeadModel({
    required this.id,
    required this.tenantId,
    required this.customerName,
    required this.contactPhone,
    required this.email,
    required this.requirementMessage,
    required this.status,
    required this.source,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.assignedEmployeeMobile,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.nextFollowUp,
    this.timeline,
    this.calls,
    this.notes,
    this.statusHistory,
    this.followUps,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      customerName: json['customerName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      email: json['email'] ?? '',
      requirementMessage: json['requirementMessage'] ?? '',
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      assignedEmployeeId: json['assignedEmployeeId'],
      assignedEmployeeName: json['assignedEmployeeName'],
      assignedEmployeeMobile: json['assignedEmployeeMobile'],
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      nextFollowUp: json['nextFollowUp'],
      timeline: json['timeline'] != null
          ? (json['timeline'] as List)
                .map((e) => TimelineEvent.fromJson(e))
                .toList()
          : null,
      calls: json['calls'] != null
          ? (json['calls'] as List).map((e) => CallRecord.fromJson(e)).toList()
          : null,
      notes: json['notes'] != null
          ? (json['notes'] as List).map((e) => NoteRecord.fromJson(e)).toList()
          : null,
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
                .map((e) => StatusHistoryRecord.fromJson(e))
                .toList()
          : null,
      followUps: json['followUps'] != null
          ? (json['followUps'] as List)
                .map((e) => FollowUpRecord.fromJson(e))
                .toList()
          : null,
    );
  }
}

class TimelineEvent {
  final String id;
  final String leadId;
  final String actorId;
  final String? actorName;
  final String action;
  final String details;
  final String timestamp;

  TimelineEvent({
    required this.id,
    required this.leadId,
    required this.actorId,
    this.actorName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'],
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class CallRecord {
  final String id;
  final String leadId;
  final String actorId;
  final String? actorName;
  final String action;
  final String details;
  final String timestamp;

  CallRecord({
    required this.id,
    required this.leadId,
    required this.actorId,
    this.actorName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'],
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class NoteRecord {
  final String id;
  final String leadId;
  final String actorId;
  final String? actorName;
  final String action;
  final String details;
  final String timestamp;

  NoteRecord({
    required this.id,
    required this.leadId,
    required this.actorId,
    this.actorName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory NoteRecord.fromJson(Map<String, dynamic> json) {
    return NoteRecord(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'],
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class StatusHistoryRecord {
  final String id;
  final String leadId;
  final String oldStatus;
  final String newStatus;
  final String changedBy;
  final String? changedByName;
  final String timestamp;

  StatusHistoryRecord({
    required this.id,
    required this.leadId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    this.changedByName,
    required this.timestamp,
  });

  factory StatusHistoryRecord.fromJson(Map<String, dynamic> json) {
    return StatusHistoryRecord(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      oldStatus: json['oldStatus'] ?? '',
      newStatus: json['newStatus'] ?? '',
      changedBy: json['changedBy'] ?? '',
      changedByName: json['changedByName'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}
