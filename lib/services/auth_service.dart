// lib/services/auth_service.dart - REPLACE COMPLETELY
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ApiResponse<LoginResponse>> login(String username, String password) async {
    try {
      print('AuthService: Starting login for user: $username');
      
      final data = {
        'username': username,
        'password': password,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/login/',
        data,
      );

      print('AuthService: API response success: ${response.isSuccess}');
      
      if (response.isSuccess) {
        final loginData = response.data!;
        print('AuthService: Login data received: ${loginData.keys}');
        
        // Safely extract data with null checks
        final token = loginData['token'];
        final userData = loginData['user'];
        final agentProfile = loginData['agent_profile'];
        
        if (token == null) {
          return ApiResponse.error('No authentication token received');
        }
        
        if (userData == null) {
          return ApiResponse.error('No user data received');
        }
        
        if (agentProfile == null) {
          return ApiResponse.error('No agent profile received');
        }
        
        print('AuthService: All required data present, storing...');
        
        // Store data
        await _storageService.storeToken(token.toString());
        await _storageService.storeUserData(Map<String, dynamic>.from(userData));
        await _storageService.storeAgentProfile(Map<String, dynamic>.from(agentProfile));

        _apiService.setToken(token.toString());

        // Parse models
        try {
          final user = User.fromJson(Map<String, dynamic>.from(userData));
          final profile = AgentProfile.fromJson(Map<String, dynamic>.from(agentProfile));
          
          print('AuthService: Models parsed successfully');

          return ApiResponse.success(LoginResponse(
            token: token.toString(),
            user: user,
            agentProfile: profile,
            message: loginData['message']?.toString() ?? 'Login successful',
          ));
        } catch (e) {
          print('AuthService: Model parsing error: $e');
          return ApiResponse.error('Failed to parse user data: $e');
        }
      }

      print('AuthService: Login failed: ${response.errorMessage}');
      return ApiResponse.error(response.errorMessage ?? 'Login failed');
      
    } catch (e) {
      print('AuthService: Exception during login: $e');
      return ApiResponse.error('Login error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.clearToken();
      await _storageService.clearUserData();
      await _storageService.clearAgentProfile();
      _apiService.clearToken();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('isLoggedIn error: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('getCurrentUser error: $e');
      return null;
    }
  }

  Future<AgentProfile?> getAgentProfile() async {
    try {
      final profileData = await _storageService.getAgentProfile();
      if (profileData != null) {
        return AgentProfile.fromJson(profileData);
      }
      return null;
    } catch (e) {
      print('getAgentProfile error: $e');
      return null;
    }
  }
}

class LoginResponse {
  final String token;
  final User user;
  final AgentProfile agentProfile;
  final String message;

  LoginResponse({
    required this.token,
    required this.user,
    required this.agentProfile,
    required this.message,
  });
}