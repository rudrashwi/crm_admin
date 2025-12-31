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
  final String createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;

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
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
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
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
