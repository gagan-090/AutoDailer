// lib/models/follow_up_model.dart - REPLACE EXISTING
import '../models/user_model.dart';

class FollowUp {
  final int id;
  final LeadInfo lead;
  final User agent;
  final DateTime followUpDate;
  final String followUpTime;
  final String? remarks;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isOverdue;
  final bool isToday;
  final String formattedDateTime;

  FollowUp({
    required this.id,
    required this.lead,
    required this.agent,
    required this.followUpDate,
    required this.followUpTime,
    this.remarks,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.isOverdue,
    required this.isToday,
    required this.formattedDateTime,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    try {
      return FollowUp(
        id: json['id'] ?? 0,
        lead: LeadInfo.fromJson(json['lead'] ?? {}),
        agent: User.fromJson(json['agent'] ?? {}),
        followUpDate: json['follow_up_date'] != null
            ? DateTime.parse(json['follow_up_date'].toString())
            : DateTime.now(),
        followUpTime: json['follow_up_time']?.toString() ?? '09:00',
        remarks: json['remarks']?.toString(),
        isCompleted: json['is_completed'] ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'].toString())
            : null,
        isOverdue: json['is_overdue'] ?? false,
        isToday: json['is_today'] ?? false,
        formattedDateTime: json['formatted_datetime']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing FollowUp from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class LeadInfo {
  final int id;
  final String name;
  final String phone;
  final String? company;

  LeadInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
  });

  factory LeadInfo.fromJson(Map<String, dynamic> json) {
    try {
      return LeadInfo(
        id: json['id'] ?? 0,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        company: json['company']?.toString(),
      );
    } catch (e) {
      print('Error parsing LeadInfo from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class FollowUpInfo {
  final int id;
  final DateTime date;
  final String time;
  final String? remarks;

  FollowUpInfo({
    required this.id,
    required this.date,
    required this.time,
    this.remarks,
  });

  factory FollowUpInfo.fromJson(Map<String, dynamic> json) {
    try {
      return FollowUpInfo(
        id: json['id'] ?? 0,
        date: json['date'] != null
            ? DateTime.parse(json['date'].toString())
            : DateTime.now(),
        time: json['time']?.toString() ?? '09:00',
        remarks: json['remarks']?.toString(),
      );
    } catch (e) {
      print('Error parsing FollowUpInfo from JSON: $e');
      rethrow;
    }
  }
}