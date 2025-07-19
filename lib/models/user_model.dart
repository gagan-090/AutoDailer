// lib/models/user_model.dart - REPLACE COMPLETELY
class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String fullName;
  final DateTime dateJoined;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.fullName,
    required this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] ?? 0,
        username: json['username']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        dateJoined: json['date_joined'] != null 
            ? DateTime.parse(json['date_joined'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing User from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class AgentProfile {
  final String department;
  final String phone;
  final DateTime hireDate;
  final int targetCallsPerDay;
  final int targetConversionsPerMonth;
  final bool isActive;

  AgentProfile({
    required this.department,
    required this.phone,
    required this.hireDate,
    required this.targetCallsPerDay,
    required this.targetConversionsPerMonth,
    required this.isActive,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    try {
      return AgentProfile(
        department: json['department']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        hireDate: json['hire_date'] != null 
            ? DateTime.parse(json['hire_date'].toString())
            : DateTime.now(),
        targetCallsPerDay: json['target_calls_per_day'] ?? 50,
        targetConversionsPerMonth: json['target_conversions_per_month'] ?? 10,
        isActive: json['is_active'] ?? true,
      );
    } catch (e) {
      print('Error parsing AgentProfile from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(T? data) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
    );
  }

  factory ApiResponse.error(String errorMessage, {int? statusCode}) {
    return ApiResponse._(
      isSuccess: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}