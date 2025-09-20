import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CivicReportApiClient {
  static const String baseUrl = 'http://localhost:8000'; // Change in production
  final Dio _dio;

  CivicReportApiClient() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode),
    );
  }

  Future<Map<String, dynamic>> submitReport({
    required String title,
    required String description,
    required String department,
    Map<String, dynamic>? location,
    String? category,
    String? urgency,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.post(
        '/reports/',
        data: {
          'title': title,
          'description': description,
          'department': department,
          'location': location,
          'category': category,
          'urgency': urgency,
          'images': imageUrls,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchReports({
    required String query,
    String? department,
    int nResults = 5,
  }) async {
    try {
      final response = await _dio.get(
        '/reports/search',
        queryParameters: {
          'query': query,
          if (department != null) 'department': department,
          'n_results': nResults,
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> getDepartments() async {
    try {
      final response = await _dio.get('/departments');
      return List<String>.from(response.data['departments']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getDepartmentReports(String department) async {
    try {
      final response = await _dio.get('/reports/$department');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please try again.');
    }

    if (e.response?.data != null && e.response?.data is Map) {
      return Exception(e.response?.data['detail'] ?? 'An error occurred');
    }

    return Exception('An unexpected error occurred');
  }
}
