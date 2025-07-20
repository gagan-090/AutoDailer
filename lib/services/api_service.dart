// lib/services/api_service.dart - ENHANCED VERSION
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      print('POST Request: ${ApiConfig.baseUrl}$endpoint');
      print('POST Data: ${jsonEncode(data)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getHeaders(token: _token),
        body: jsonEncode(data),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('Network error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams) 
          : uri;

      print('GET Request: $uriWithParams');
      
      final response = await http.get(
        uriWithParams,
        headers: ApiConfig.getHeaders(token: _token),
      );

      print('Response Status: ${response.statusCode}');
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('Network error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      print('PATCH Request: ${ApiConfig.baseUrl}$endpoint');
      print('PATCH Data: ${jsonEncode(data)}');
      
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getHeaders(token: _token),
        body: jsonEncode(data),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('Network error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      print('DELETE Request: ${ApiConfig.baseUrl}$endpoint');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getHeaders(token: _token),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('Network error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      print('PUT Request: ${ApiConfig.baseUrl}$endpoint');
      print('PUT Data: ${jsonEncode(data)}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getHeaders(token: _token),
        body: jsonEncode(data),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('Network error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse.success(null);
      }
      
      try {
        final jsonData = jsonDecode(response.body);
        print('Parsed JSON: $jsonData');
        
        if (fromJson != null && jsonData is Map<String, dynamic>) {
          final data = fromJson(jsonData);
          return ApiResponse.success(data);
        } else {
          return ApiResponse.success(jsonData);
        }
      } catch (e) {
        print('JSON parsing error: $e');
        return ApiResponse.error('Failed to parse response');
      }
    } else if (statusCode == 204) {
      // No content - successful deletion
      return ApiResponse.success(null);
    } else {
      // Try to extract error message from response
      String errorMessage = 'Request failed: $statusCode';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['error'] ?? errorData['detail'] ?? errorMessage;
        }
      } catch (e) {
        // Use default error message if parsing fails
      }
      
      return ApiResponse.error(errorMessage);
    }
  }
}