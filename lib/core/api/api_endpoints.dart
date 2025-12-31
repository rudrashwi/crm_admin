class ApiEndpoints {
  static const String baseUrl = 'http://13.232.29.190:8080';

  // Auth
  static const String registerAdmin = '/auth/admin/register';
  static const String login = '/auth/login';
  static const String checkUsername = '/public/username/check';

  // Users
  static const String createUser = '/users/create';
  static const String getEmployees = '/analytics/employees';
  static String terminateUser(String userId) => '/users/$userId/terminate';
  static String reactivateUser(String userId) => '/users/$userId/reactivate';

  // Leads
  static const String createLead = '/leads';
  static const String getAllLeads = '/admin/leads/all';
  static String deleteLead(String leadId) => '/leads/$leadId';
  static String updateLead(String leadId) => '/leads/$leadId';
  static String assignLead(String leadId, String userId) => '/assignments/assign/$leadId/to/$userId';
  static String unassignLead(String leadId) => '/assignments/unassign/$leadId';

  // Analytics
  static const String dashboard = '/analytics/dashboard';
  static const String realtimeStats = '/analytics/realtime/stats';
  static String employeeDetails(String employeeId) => '/analytics/employee/$employeeId';
}
