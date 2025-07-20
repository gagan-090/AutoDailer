// lib/config/api_config.dart - REPLACE COMPLETELY
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.10:8000/api';
  
  static const String loginEndpoint = '/auth/login/';
  static const String logoutEndpoint = '/auth/logout/';
  static const String profileEndpoint = '/auth/profile/';
  
  static const String leadsEndpoint = '/leads/';
  static const String myLeadsEndpoint = '/leads/my_leads/';
  
  static const String dashboardEndpoint = '/agent/dashboard/';
  static const String statsEndpoint = '/agent/stats/';
  
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    
    return headers;
  }
}

// REMOVE ApiResponse from here - it's now only in user_model.dart