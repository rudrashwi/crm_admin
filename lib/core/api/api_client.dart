import 'package:dio/dio.dart';
import 'package:crm_admin/core/utils/logger.dart';
import 'package:crm_admin/core/utils/pref_manager.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = PrefManager.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Add Tenant ID if available
        final tenantId = PrefManager.getTenantId();
        if (tenantId != null) {
          options.headers['X-Tenant-Id'] = tenantId;
        }

        AppLogger.i('REQUEST[${options.method}] => PATH: ${options.path}');
        AppLogger.d('Headers: ${options.headers}');
        AppLogger.d('Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        AppLogger.d('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        AppLogger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        AppLogger.e('Message: ${e.message}');
        AppLogger.e('Response: ${e.response?.data}');
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      rethrow;
    }
  }
}
