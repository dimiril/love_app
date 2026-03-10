import 'package:dio/dio.dart';
import 'dio_service.dart';

abstract class BaseService {
  final Dio _dio = DioService().dio;

  Future<Response?> safeGet(String url, {Map<String, dynamic>? queryParameters, int retries = 2}) async {
    int attempt = 0;
    while (attempt <= retries) {
      try {
        return await _dio.get(url, queryParameters: queryParameters);
      } on DioException catch (e) {
        attempt++;
        if (attempt > retries) {
          _handleDioError(e, url);
          return null;
        }
      }
    }
    return null;
  }

  Future<Response?> safePost(String url, {dynamic data, int retries = 2}) async {
    int attempt = 0;
    while (attempt <= retries) {
      try {
        return await _dio.post(url, data: data);
      } on DioException catch (e) {
        attempt++;
        if (attempt > retries) {
          _handleDioError(e, url);
          return null;
        }
      }
    }
    return null;
  }

  void _handleDioError(DioException e, String context) {
    if (e.response?.statusCode == 401) {
      print('❌ Unauthorized in $context - check API Key');
    } else if (e.response?.statusCode == 426) {
      print('⚠️ App version outdated in $context - forced update required');
      // already handled once by DioService callback
    } else {
      print('DioException in $context: ${e.message}');
    }
  }



}