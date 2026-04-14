import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:flutter/foundation.dart'; // Add this

class ApiService {
  final Dio _dio = Dio();
  // Use production Render URL
  final String baseUrl = kIsWeb
      ? 'https://athiban-traders-app.onrender.com/api'
      : 'https://athiban-traders-app.onrender.com/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Here you would inject JWT token if auth is implemented locally
          final box = await Hive.openBox('settings');
          final token = box.get('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}
