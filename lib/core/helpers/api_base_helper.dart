import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class ApiBaseHelper {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://mrmtest.eu.ngrok.io',
    connectTimeout: const Duration(seconds: 60), // Increased timeout
    receiveTimeout: const Duration(seconds: 60), // Increased timeout
  ));

  ApiBaseHelper() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>HttpClient()..badCertificateCallback =(X509Certificate cert, String host, int port) => true;
    // Add logging interceptor for debugging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
          logPrint: (obj) {
            // Use debugPrint for Flutter console output
            debugPrint(obj.toString());
          },
        ),
      );
    }
  }

  Future<Response> get(String url) async {
    try {
      final response = await _dio.get(url);
      return response;
    } on DioException catch (e) { // Catch DioException specifically
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in GET $url: $e');
      rethrow;
    }
  }

  Future<Response> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(url, data: body);
      return response;
    } on DioException catch (e) { // Catch DioException specifically
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in POST $url with body $body: $e');
      rethrow;
    }
  }

  void _handleError(DioException error) {
    String errorMessage = 'An unknown error occurred.';
    if (error.response != null) {
      // Server responded with a status code other than 2xx
      errorMessage = 'Error: ${error.response?.statusCode} - ${error.response?.statusMessage}';
      if (error.response?.data != null) {
        errorMessage += '\nDetails: ${error.response?.data.toString()}';
      }
    } else {
      // Request was made but no response was received (e.g., network error, timeout)
      if (error.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Receive timeout. The server took too long to respond.';
      } else if (error.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Send timeout. Failed to send data to the server.';
      } else if (error.type == DioExceptionType.badResponse) {
        errorMessage = 'Bad response from server.';
      } else if (error.type == DioExceptionType.unknown) {
        if (error.error is SocketException) {
          errorMessage = 'Network error: Please check your internet connection.';
        } else {
          errorMessage = 'Unknown error occurred: ${error.message}';
        }
      }
    }
    debugPrint('Dio Error: $errorMessage');
    // You might want to throw a custom exception here or show a user-friendly message.
  }
}