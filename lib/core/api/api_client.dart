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
    _dio.interceptors.add(
      InterceptorsWrapper(
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
          AppLogger.i(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          AppLogger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final path = e.requestOptions.path;
          final statusCode = e.response?.statusCode;

          // Special handling for expected 401 on device token registration during app startup
          if (statusCode == 401 && path == ApiEndpoints.registerDeviceToken) {
            AppLogger.i(
              'INFO: Token registration skipped - user not authenticated (expected during app startup)',
            );
            return handler.next(e);
          }

          AppLogger.e('ERROR[$statusCode] => PATH: $path');
          AppLogger.e('Message: ${e.message}');
          AppLogger.e('Response: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, extraHeaders);
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, extraHeaders);
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, extraHeaders);
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, extraHeaders);
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Options _mergeOptions(Options? options, Map<String, dynamic>? extraHeaders) {
    if (extraHeaders == null || extraHeaders.isEmpty) {
      return options ?? Options();
    }

    // Create new options with extra headers
    // The interceptor will add Authorization and X-Tenant-Id automatically
    final headers = <String, dynamic>{};
    if (options?.headers != null) {
      headers.addAll(options!.headers!);
    }
    headers.addAll(extraHeaders);

    return Options(
      method: options?.method,
      sendTimeout: options?.sendTimeout,
      receiveTimeout: options?.receiveTimeout,
      extra: options?.extra,
      headers: headers,
      responseType: options?.responseType,
      contentType: options?.contentType,
      validateStatus: options?.validateStatus,
      receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
      followRedirects: options?.followRedirects,
      maxRedirects: options?.maxRedirects,
      persistentConnection: options?.persistentConnection,
      requestEncoder: options?.requestEncoder,
      responseDecoder: options?.responseDecoder,
      listFormat: options?.listFormat,
    );
  }
}
