// lib/services/storage_service.dart - REPLACE COMPLETELY
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _agentProfileKey = 'agent_profile';

  // Token management - using SharedPreferences only for now
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // User data management
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // Agent profile management
  Future<void> storeAgentProfile(Map<String, dynamic> agentProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_agentProfileKey, jsonEncode(agentProfile));
  }

  Future<Map<String, dynamic>?> getAgentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString(_agentProfileKey);
    if (profileString != null) {
      return jsonDecode(profileString);
    }
    return null;
  }

  Future<void> clearAgentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_agentProfileKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}