// lib/models/call_log_model.dart
import 'lead_info_model.dart';
import 'user_model.dart';

class CallLog {
  final int id;
  final LeadInfo lead;
  final User agent;
  final DateTime callDate;
  final Duration? duration;
  final String? durationDisplay;
  final String disposition;
  final String dispositionDisplay;
  final String? remarks;
  final DateTime createdAt;

  CallLog({
    required this.id,
    required this.lead,
    required this.agent,
    required this.callDate,
    this.duration,
    this.durationDisplay,
    required this.disposition,
    required this.dispositionDisplay,
    this.remarks,
    required this.createdAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      lead: LeadInfo.fromJson(json['lead']),
      agent: User.fromJson(json['agent']),
      callDate: DateTime.parse(json['call_date']),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      durationDisplay: json['duration_display'],
      disposition: json['disposition'],
      dispositionDisplay: json['disposition_display'],
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
