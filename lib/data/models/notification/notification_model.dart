class NotificationModel {
  final String id;
  final String userId;
  final String? tenantId;
  final String title;
  final String message;
  final String type;
  final String? data;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tenantId: json['tenantId'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      data: json['data'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tenantId': tenantId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? tenantId,
    String? title,
    String? message,
    String? type,
    String? data,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
