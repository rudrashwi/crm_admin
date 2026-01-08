class ReportModel {
  final String id;
  final String tenantId;
  final String requestedBy;
  final String reportType;
  final Map<String, dynamic> filters;
  final String format;
  final String deliveryMethod;
  final String status;
  final String? generatedAt;
  final String? expiresAt;
  final String? downloadUrl;
  final String? filePath;
  final bool emailSent;
  final String? emailTo;
  final String? downloadToken;
  final String? errorMessage;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.tenantId,
    required this.requestedBy,
    required this.reportType,
    required this.filters,
    required this.format,
    required this.deliveryMethod,
    required this.status,
    this.generatedAt,
    this.expiresAt,
    this.downloadUrl,
    this.filePath,
    required this.emailSent,
    this.emailTo,
    this.downloadToken,
    this.errorMessage,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      reportType: json['reportType'] ?? '',
      filters: json['filters'] ?? {},
      format: json['format'] ?? '',
      deliveryMethod: json['deliveryMethod'] ?? '',
      status: json['status'] ?? '',
      generatedAt: json['generatedAt'],
      expiresAt: json['expiresAt'],
      downloadUrl: json['downloadUrl'],
      filePath: json['filePath'],
      emailSent: json['emailSent'] ?? false,
      emailTo: json['emailTo'],
      downloadToken: json['downloadToken'],
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}
