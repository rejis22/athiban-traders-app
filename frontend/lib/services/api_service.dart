import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://athiban-traders-app.onrender.com/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    // ADD THIS — shows exact error in console
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final box = await Hive.openBox('settings');
          final token = box.get('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // ADD THIS — print full error details
          debugPrint('=== DIO ERROR ===');
          debugPrint('Type: ${e.type}');
          debugPrint('Message: ${e.message}');
          debugPrint('Response: ${e.response}');
          debugPrint('Error: ${e.error}');
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}
