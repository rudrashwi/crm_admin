/// Model for lead interaction API request and response
class LeadInteractionRequest {
  final String? callNotes;
  final int? callDuration; // in seconds
  final String callType;
  final String? remark;
  final String? followUpStatus;
  final String? followUpNotes;
  final String? scheduledDateTime; // ISO 8601 format

  LeadInteractionRequest({
    this.callNotes,
    this.callDuration,
    required this.callType,
    this.remark,
    this.followUpStatus,
    this.followUpNotes,
    this.scheduledDateTime,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'callType': callType};

    if (callNotes != null && callNotes!.isNotEmpty) {
      map['callNotes'] = callNotes;
    }
    if (callDuration != null) {
      map['callDuration'] = callDuration;
    }
    if (remark != null && remark!.isNotEmpty) {
      map['remark'] = remark;
    }
    if (followUpStatus != null && followUpStatus!.isNotEmpty) {
      map['followUpStatus'] = followUpStatus;
    }
    if (followUpNotes != null && followUpNotes!.isNotEmpty) {
      map['followUpNotes'] = followUpNotes;
    }
    if (scheduledDateTime != null && scheduledDateTime!.isNotEmpty) {
      map['scheduledDateTime'] = scheduledDateTime;
    }

    return map;
  }
}

/// Call types for lead interaction
class CallType {
  static const String newLead = 'NEW';
  static const String assigned = 'ASSIGNED';
  static const String followUpScheduled = 'FOLLOW_UP_SCHEDULED';
  static const String callbackRequested = 'CALLBACK_REQUESTED';
  static const String noResponse = 'NO_RESPONSE';
  static const String completed = 'COMPLETED';
  static const String closed = 'CLOSED';
  static const String cancelled = 'CANCELLED';

  static List<String> get all => [
    newLead,
    assigned,
    followUpScheduled,
    callbackRequested,
    noResponse,
    completed,
    closed,
    cancelled,
  ];

  static String getDisplayName(String callType) {
    switch (callType) {
      case newLead:
        return 'New Lead';
      case assigned:
        return 'Assigned';
      case followUpScheduled:
        return 'Follow-up Scheduled';
      case callbackRequested:
        return 'Callback Requested';
      case noResponse:
        return 'No Response';
      case completed:
        return 'Completed';
      case closed:
        return 'Closed';
      case cancelled:
        return 'Cancelled';
      default:
        return callType;
    }
  }
}

/// Follow-up model for lead detail response
class FollowUpRecord {
  final String id;
  final String leadId;
  final String employeeId;
  final String? employeeName;
  final String status;
  final String? notes;
  final String? scheduledDateTime;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final String? callCompletedAt;
  final bool notificationSent;

  FollowUpRecord({
    required this.id,
    required this.leadId,
    required this.employeeId,
    this.employeeName,
    required this.status,
    this.notes,
    this.scheduledDateTime,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.callCompletedAt,
    required this.notificationSent,
  });

  factory FollowUpRecord.fromJson(Map<String, dynamic> json) {
    return FollowUpRecord(
      id: json['id'] ?? '',
      leadId: json['leadId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'],
      status: json['status'] ?? '',
      notes: json['notes'],
      scheduledDateTime: json['scheduledDateTime'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      closedAt: json['closedAt'],
      callCompletedAt: json['callCompletedAt'],
      notificationSent: json['notificationSent'] ?? false,
    );
  }
}
