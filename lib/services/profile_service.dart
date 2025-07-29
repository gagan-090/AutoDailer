// lib/services/profile_service.dart
import '../models/user_model.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> getProfileStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/profile/stats/',
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch profile stats: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentActivities() async {
    try {
      final response = await _apiService.get<List<Map<String, dynamic>>>(
        '/api/profile/recent-activities/',
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch recent activities: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;

      final response = await _apiService.patch<Map<String, dynamic>>(
        '/api/profile/update/',
        data,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update profile: $e');
    }
  }
}