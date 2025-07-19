// lib/services/lead_service.dart
import '../models/user_model.dart';
import '../models/lead_model.dart';
import 'api_service.dart';

class LeadService {
  static final LeadService _instance = LeadService._internal();
  factory LeadService() => _instance;
  LeadService._internal();

  final ApiService _apiService = ApiService();

  // Get agent's assigned leads
  Future<ApiResponse<List<Lead>>> getMyLeads({
    String? status,
    String? search,
    String? ordering,
  }) async {
    try {
      Map<String, String> queryParams = {};
      
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _apiService.get<Map<String, dynamic>>(
        '/leads/my_leads/',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data!;
        final results = responseData['results'] as List;
        final leads = results.map((leadJson) => Lead.fromJson(leadJson)).toList();
        
        print('LeadService: Loaded ${leads.length} leads');
        return ApiResponse.success(leads);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load leads');
    } catch (e) {
      print('LeadService error: $e');
      return ApiResponse.error('Error loading leads: $e');
    }
  }

  // Get lead details
  Future<ApiResponse<Lead>> getLeadDetail(int leadId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/leads/$leadId/',
      );

      if (response.isSuccess) {
        final lead = Lead.fromJson(response.data!);
        return ApiResponse.success(lead);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load lead');
    } catch (e) {
      return ApiResponse.error('Error loading lead: $e');
    }
  }

  // Update lead status
  Future<ApiResponse<Lead>> updateLeadStatus(int leadId, String status, {String? notes}) async {
    try {
      final data = {'status': status};
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.patch<Map<String, dynamic>>(
        '/leads/$leadId/update_status/',
        data,
      );

      if (response.isSuccess) {
        final lead = Lead.fromJson(response.data!);
        return ApiResponse.success(lead);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to update lead');
    } catch (e) {
      return ApiResponse.error('Error updating lead: $e');
    }
  }

  // Create call log
  Future<ApiResponse<void>> createCallLog(int leadId, {
    required String disposition,
    String? remarks,
    int? duration,
    String? leadStatus,
  }) async {
    try {
      final data = {
        'disposition': disposition,
        if (remarks != null) 'remarks': remarks,
        if (duration != null) 'duration': duration,
        if (leadStatus != null) 'lead_status': leadStatus,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/leads/$leadId/call/',
        data,
      );

      if (response.isSuccess) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to log call');
    } catch (e) {
      return ApiResponse.error('Error logging call: $e');
    }
  }

  // Get agent dashboard data
  Future<ApiResponse<DashboardData>> getDashboardData() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/agent/dashboard/',
      );

      if (response.isSuccess) {
        final dashboardData = DashboardData.fromJson(response.data!);
        return ApiResponse.success(dashboardData);
      }

      return ApiResponse.error(response.errorMessage ?? 'Failed to load dashboard');
    } catch (e) {
      return ApiResponse.error('Error loading dashboard: $e');
    }
  }
}