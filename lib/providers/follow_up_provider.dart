// lib/providers/follow_up_provider.dart - BASIC VERSION
import 'package:flutter/material.dart';
import '../models/follow_up_model.dart';
import '../services/api_service.dart';

class FollowUpProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FollowUp> _followUps = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FollowUp> get followUps => _followUps;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered follow-ups
  List<FollowUp> get todayFollowUps {
    final today = DateTime.now();
    return _followUps.where((followUp) {
      return !followUp.isCompleted &&
          followUp.followUpDate.year == today.year &&
          followUp.followUpDate.month == today.month &&
          followUp.followUpDate.day == today.day;
    }).toList();
  }

  List<FollowUp> get upcomingFollowUps {
    final today = DateTime.now();
    return _followUps.where((followUp) {
      return !followUp.isCompleted && followUp.followUpDate.isAfter(today);
    }).toList();
  }

  List<FollowUp> get overdueFollowUps {
    final now = DateTime.now();
    return _followUps.where((followUp) {
      if (followUp.isCompleted) return false;
      return followUp.followUpDate.isBefore(now);
    }).toList();
  }

  // Statistics
  int get totalFollowUps => _followUps.length;
  int get pendingFollowUps => _followUps.where((f) => !f.isCompleted).length;
  int get completedCount => _followUps.where((f) => f.isCompleted).length;
  int get overdueCount => overdueFollowUps.length;
  int get todayCount => todayFollowUps.length;

  // Load follow-ups from API
  Future<void> loadFollowUps({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get<Map<String, dynamic>>('/follow-ups/');

      if (response.isSuccess) {
        final responseData = response.data!;
        final results = responseData['results'] as List? ?? responseData as List? ?? [];
        _followUps = results.map((json) => FollowUp.fromJson(json)).toList();
        print('FollowUpProvider: Loaded ${_followUps.length} follow-ups');
      } else {
        _errorMessage = response.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Failed to load follow-ups: $e';
      print('FollowUpProvider error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mark follow-up as completed
  Future<bool> markAsCompleted(int followUpId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/follow-ups/$followUpId/mark_completed/',
        {},
      );

      if (response.isSuccess) {
        // Update local data
        final index = _followUps.indexWhere((f) => f.id == followUpId);
        if (index != -1) {
          _followUps[index] = FollowUp.fromJson(response.data!);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to mark follow-up as completed: $e';
      notifyListeners();
      return false;
    }
  }

  // Create new follow-up
  Future<bool> createFollowUp({
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
        // Refresh the list
        await loadFollowUps(refresh: true);
        return true;
      } else {
        _errorMessage = response.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create follow-up: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get follow-up statistics for dashboard
  Map<String, dynamic> getStatistics() {
    return {
      'total': totalFollowUps,
      'pending': pendingFollowUps,
      'completed': completedCount,
      'overdue': overdueCount,
      'today': todayCount,
      'completionRate': totalFollowUps > 0 ? (completedCount / totalFollowUps * 100).round() : 0,
    };
  }

  // Refresh data
  Future<void> refresh() async {
    await loadFollowUps(refresh: true);
  }
}