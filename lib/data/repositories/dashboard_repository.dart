import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';
import 'package:crm_admin/data/models/dashboard/dashboard_stats.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      return DashboardStats.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<DashboardStats> getRealtimeStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.realtimeStats);
      return DashboardStats.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
