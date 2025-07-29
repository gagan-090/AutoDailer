// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  Map<String, dynamic>? _profileStats;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get profileStats => _profileStats;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load profile stats
  Future<void> loadProfileStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.getProfileStats();
      
      if (response.isSuccess) {
        _profileStats = response.data;
      } else {
        _errorMessage = response.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile stats: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load recent activities
  Future<void> loadRecentActivities() async {
    try {
      final response = await _profileService.getRecentActivities();
      
      if (response.isSuccess) {
        _recentActivities = response.data ?? [];
      } else {
        _errorMessage = response.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Failed to load recent activities: $e';
    }
    
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileService.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      
      if (response.isSuccess) {
        // Reload stats after profile update
        await loadProfileStats();
        return true;
      } else {
        _errorMessage = response.errorMessage;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}