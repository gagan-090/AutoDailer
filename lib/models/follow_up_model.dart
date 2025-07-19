// lib/models/follow_up_model.dart
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
    return FollowUp(
      id: json['id'],
      lead: LeadInfo.fromJson(json['lead']),
      agent: User.fromJson(json['agent']),
      followUpDate: DateTime.parse(json['follow_up_date']),
      followUpTime: json['follow_up_time'],
      remarks: json['remarks'],
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      isOverdue: json['is_overdue'] ?? false,
      isToday: json['is_today'] ?? false,
      formattedDateTime: json['formatted_datetime'] ?? '',
    );
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
    return FollowUpInfo(
      id: json['id'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      remarks: json['remarks'],
    );
  }
}
