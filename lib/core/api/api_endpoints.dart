class ApiEndpoints {
  static const String baseUrl = 'http://13.232.29.190:8080';

  // Auth
  static const String registerAdmin = '/auth/admin/register';
  static const String login = '/auth/login';
  static const String checkUsername = '/public/username/check';

  // Users
  static const String createUser = '/users/create';
  static String getUsersByTenant(String tenantId) => '/users/tenant/$tenantId';
  static const String getEmployees = '/analytics/employees';
  static String terminateUser(String userId) => '/users/$userId/terminate';
  static String reactivateUser(String userId) => '/users/$userId/reactivate';
  static String adminResetPassword(String userId) =>
      '/admin/users/$userId/reset-password';

  // Leads
  static const String createLead = '/leads';
  static const String getAllLeads = '/admin/leads/all';
  static String getLeadDetails(String leadId) => '/leads/$leadId/details';
  static String deleteLead(String leadId) => '/leads/$leadId';
  static String updateLead(String leadId) => '/leads/$leadId';
  static String assignLead(String leadId, String userId) =>
      '/assignments/assign/$leadId/to/$userId';
  static String unassignLead(String leadId) => '/assignments/unassign/$leadId';
  static const String batchAssignLeads = '/assignments/batch';
  static const String validateLeadsExcel = '/leads/validate';
  static const String uploadLeadsExcel = '/leads/upload';
  static String addLeadRemark(String leadId) => '/leads/$leadId/remark';
  static String logLeadCall(String leadId) => '/leads/$leadId/call';
  static String leadInteraction(String leadId) => '/leads/$leadId/interaction';

  // Notifications
  static const String registerDeviceToken = '/notifications/device';
  static const String myNotifications = '/notifications/my';
  static String markNotificationRead(String notificationId) =>
      '/notifications/$notificationId/read';

  // Reports
  static const String generateReport = '/reports/generate';
  static String downloadReport(String reportId) =>
      '/reports/$reportId/download';

  // Analytics
  static const String dashboard = '/analytics/dashboard';
  static const String realtimeStats = '/analytics/realtime/stats';
  static String employeeDetails(String employeeId) =>
      '/analytics/employee/$employeeId';

  // Subscriptions
  static String getUserSubscription(String userId) =>
      '/subscriptions/user/$userId';
  static const String subscriptionPricing = '/subscriptions/pricing';
  static const String estimateCustomPlan = '/subscriptions/estimate-custom';
  static const String requestCustomPlan = '/subscriptions/request-custom';
  static const String mySubscriptionRequests = '/subscriptions/my-requests';

  // Public Content
  static const String publicContent = '/public/content';
}
