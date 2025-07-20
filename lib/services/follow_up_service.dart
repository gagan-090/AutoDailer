// lib/services/follow_up_service.dart
import '../models/user_model.dart';
import '../models/follow_up_model.dart';
import 'api_service.dart';

class FollowUpService {
  static final FollowUpService _instance = FollowUpService._internal();
  factory FollowUpService() => _instance;
  FollowUpService._internal();

  final ApiService _apiService = ApiService();

  // Get all follow-ups for current agent
  Future<ApiResponse<List<FollowUp>>> getFollowUps({
    bool? completed,
    String? date,
  }) async {
    try {
      Map<String, String> queryParams = {};
      
      if (completed != null) {
        queryParams['completed'] = completed.toString();
      }
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/follow-ups/',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data!;
        final results = responseData['results'] as List? ?? responseData as List;
        final followUps = results.map((json) => FollowUp.fromJson(json)).toList();
        
        print('FollowUpService: Loaded ${followUps.length} follow-ups');
        return ApiResponse.success(followUps);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load follow-ups');
    } catch (e) {
      print('FollowUpService error: $e');
      return ApiResponse.error('Error loading follow-ups: $e');
    }
  }

  // Get today's follow-ups
  Future<ApiResponse<List<FollowUp>>> getTodayFollowUps() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/follow-ups/today/',
      );

      if (response.isSuccess) {
        final results = response.data as List? ?? [];
        final followUps = results.map((json) => FollowUp.fromJson(json)).toList();
        return ApiResponse.success(followUps);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load today\'s follow-ups');
    } catch (e) {
      return ApiResponse.error('Error loading today\'s follow-ups: $e');
    }
  }

  // Get overdue follow-ups
  Future<ApiResponse<List<FollowUp>>> getOverdueFollowUps() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/follow-ups/overdue/',
      );

      if (response.isSuccess) {
        final results = response.data as List? ?? [];
        final followUps = results.map((json) => FollowUp.fromJson(json)).toList();
        return ApiResponse.success(followUps);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load overdue follow-ups');
    } catch (e) {
      return ApiResponse.error('Error loading overdue follow-ups: $e');
    }
  }

  // Create new follow-up
  Future<ApiResponse<FollowUp>> createFollowUp({
    required int leadId,
    required DateTime followUpDate,
    required String followUpTime,
    String? remarks,
  }) async {
    try {
      final data = {
        'lead_id': leadId,
        'follow_up_date': followUpDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'follow_up_time': followUpTime,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/follow-ups/',
        data,
      );

      if (response.isSuccess) {
        final followUp = FollowUp.fromJson(response.data!);
        return ApiResponse.success(followUp);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to create follow-up');
    } catch (e) {
      return ApiResponse.error('Error creating follow-up: $e');
    }
  }

  // Create follow-up for specific lead
  Future<ApiResponse<FollowUp>> createFollowUpForLead({
    required int leadId,
    required DateTime followUpDate,
    required String followUpTime,
    String? remarks,
  }) async {
    try {
      final data = {
        'follow_up_date': followUpDate.toIso8601String().split('T')[0],
        'follow_up_time': followUpTime,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/leads/$leadId/follow-up/',
        data,
      );

      if (response.isSuccess) {
        final followUp = FollowUp.fromJson(response.data!);
        return ApiResponse.success(followUp);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to create follow-up');
    } catch (e) {
      return ApiResponse.error('Error creating follow-up: $e');
    }
  }

  // Mark follow-up as completed
  Future<ApiResponse<FollowUp>> markAsCompleted(int followUpId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/follow-ups/$followUpId/mark_completed/',
        {},
      );

      if (response.isSuccess) {
        final followUp = FollowUp.fromJson(response.data!);
        return ApiResponse.success(followUp);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to mark follow-up as completed');
    } catch (e) {
      return ApiResponse.error('Error completing follow-up: $e');
    }
  }

  // Update follow-up
  Future<ApiResponse<FollowUp>> updateFollowUp({
    required int followUpId,
    DateTime? followUpDate,
    String? followUpTime,
    String? remarks,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (followUpDate != null) {
        data['follow_up_date'] = followUpDate.toIso8601String().split('T')[0];
      }
      if (followUpTime != null) {
        data['follow_up_time'] = followUpTime;
      }
      if (remarks != null) {
        data['remarks'] = remarks;
      }

      final response = await _apiService.patch<Map<String, dynamic>>(
        '/follow-ups/$followUpId/',
        data,
      );

      if (response.isSuccess) {
        final followUp = FollowUp.fromJson(response.data!);
        return ApiResponse.success(followUp);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to update follow-up');
    } catch (e) {
      return ApiResponse.error('Error updating follow-up: $e');
    }
  }

  // Delete follow-up
  Future<ApiResponse<void>> deleteFollowUp(int followUpId) async {
    try {
      final response = await _apiService.delete<void>(
        '/follow-ups/$followUpId/',
      );

      if (response.isSuccess) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to delete follow-up');
    } catch (e) {
      return ApiResponse.error('Error deleting follow-up: $e');
    }
  }

  // Get follow-up details
  Future<ApiResponse<FollowUp>> getFollowUpDetails(int followUpId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/follow-ups/$followUpId/',
      );

      if (response.isSuccess) {
        final followUp = FollowUp.fromJson(response.data!);
        return ApiResponse.success(followUp);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load follow-up details');
    } catch (e) {
      return ApiResponse.error('Error loading follow-up details: $e');
    }
  }

  // Get follow-ups for specific lead
  Future<ApiResponse<List<FollowUp>>> getFollowUpsForLead(int leadId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/leads/$leadId/follow-ups/',
      );

      if (response.isSuccess) {
        final results = response.data!['results'] as List? ?? response.data as List? ?? [];
        final followUps = results.map((json) => FollowUp.fromJson(json)).toList();
        return ApiResponse.success(followUps);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load follow-ups for lead');
    } catch (e) {
      return ApiResponse.error('Error loading follow-ups for lead: $e');
    }
  }

  // Bulk mark follow-ups as completed
  Future<ApiResponse<void>> bulkMarkAsCompleted(List<int> followUpIds) async {
    try {
      final data = {
        'follow_up_ids': followUpIds,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/follow-ups/bulk-complete/',
        data,
      );

      if (response.isSuccess) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to bulk complete follow-ups');
    } catch (e) {
      return ApiResponse.error('Error bulk completing follow-ups: $e');
    }
  }

  // Snooze follow-up (reschedule to later)
  Future<ApiResponse<FollowUp>> snoozeFollowUp({
    required int followUpId,
    required Duration snoozeFor,
  }) async {
    try {
      final now = DateTime.now();
      final newDateTime = now.add(snoozeFor);
      
      return await updateFollowUp(
        followUpId: followUpId,
        followUpDate: newDateTime,
        followUpTime: '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      return ApiResponse.error('Error snoozing follow-up: $e');
    }
  }

  // Get follow-up statistics
  Future<ApiResponse<Map<String, dynamic>>> getFollowUpStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/follow-ups/stats/',
      );

      if (response.isSuccess) {
        return ApiResponse.success(response.data!);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load follow-up statistics');
    } catch (e) {
      return ApiResponse.error('Error loading follow-up statistics: $e');
    }
  }
}