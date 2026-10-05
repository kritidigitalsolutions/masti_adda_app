import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/core/data/exception/app_exception.dart';
import 'package:masti_adda_app/core/data/network/base_api_service.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';

class NetworkApiService extends BaseApiService {
  late Dio _dio;

  NetworkApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {"Content-Type": "application/json"},
      ),
    );

    /// Interceptor for logging + auto-attaching the auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          debugPrint("➡️ REQUEST [${options.method}] => ${options.uri}");
          final safeHeaders = Map<String, dynamic>.from(options.headers);
          if (safeHeaders.containsKey("Authorization")) {
            safeHeaders["Authorization"] = "Bearer ***";
          }
          debugPrint("Headers: $safeHeaders");
          debugPrint("Data: ${options.data}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ RESPONSE [${response.statusCode}] => ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ ERROR [${e.response?.statusCode}] => ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
    debugPrint("🔐 Authorization token set");
  }

  /// ❌ Remove Token (Logout)
  void clearToken() {
    _dio.options.headers.remove("Authorization");
    debugPrint("🔓 Token Cleared");
  }

  @override
  Future<dynamic> getApi(String url) async {
    try {
      debugPrint("GET API CALL => $url");
      final response = await _dio.get(url);
      return returnResponse(response);
    } on DioException catch (e) {
      debugPrint("GET API ERROR => ${e.message}");
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> postApi(String url, dynamic data) async {
    try {
      debugPrint("POST API CALL => $url");
      debugPrint("POST DATA => $data");

      final response = await _dio.post(url, data: data);
      return returnResponse(response);
    } on DioException catch (e) {
      debugPrint("POST API ERROR => ${e.message}");
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> pacthApi(String url, dynamic data) async {
    try {
      debugPrint("POST API CALL => $url");
      debugPrint("POST DATA => $data");

      final response = await _dio.patch(url, data: data);
      return returnResponse(response);
    } on DioException catch (e) {
      debugPrint("POST API ERROR => ${e.message}");
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> putApi(String url, dynamic data) async {
    try {
      debugPrint("PUT API CALL => $url");
      debugPrint("PUT DATA => $data");

      final response = await _dio.put(url, data: data);
      return returnResponse(response);
    } on DioException catch (e) {
      debugPrint("PUT API ERROR => ${e.message}");
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> deleteApi(String url, dynamic data) async {
    try {
      debugPrint("DELETE API CALL => $url");

      final response = await _dio.delete(url, data: data);
      return returnResponse(response);
    } on DioException catch (e) {
      debugPrint("DELETE API ERROR => ${e.message}");
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException error) {
    debugPrint("HANDLE ERROR => ${error.response?.data}");

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FetchDataException("Connection timeout");

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _extractErrorMessage(error.response?.data);

        if (statusCode == 400) {
          return BadRequestException(message);
        } else if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedException(message);
        } else if (statusCode >= 500) {
          return FetchDataException(message);
        } else {
          return BadRequestException(message);
        }

      case DioExceptionType.cancel:
        return FetchDataException("Request cancelled");

      case DioExceptionType.unknown:
      default:
        return FetchDataException("No Internet Connection");
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) return data.trim();
    return "Something went wrong. Please try again.";
  }
}

dynamic returnResponse(Response response) {
  switch (response.statusCode) {
    case 200:
    case 201:
      return response.data;

    case 400:
      throw BadRequestException(response.data.toString());

    case 401:
    case 403:
      throw UnauthorizedException(response.data.toString());

    case 500:
    default:
      throw FetchDataException(
        "Error occurred with status code : ${response.statusCode}",
      );
  }
}
