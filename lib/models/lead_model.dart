// lib/models/lead_model.dart
import 'package:flutter/material.dart';
import 'user_model.dart';

class Lead {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? company;
  final String status;
  final String statusDisplay;
  final User? assignedAgent;
  final String? source;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int callCount;
  final DateTime? lastCallDate;
  final String? lastCallDisposition;
  final int followUpCount;

  Lead({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.company,
    required this.status,
    required this.statusDisplay,
    this.assignedAgent,
    this.source,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.callCount,
    this.lastCallDate,
    this.lastCallDisposition,
    required this.followUpCount,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    try {
      return Lead(
        id: json['id'] ?? 0,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        company: json['company']?.toString(),
        status: json['status']?.toString() ?? 'new',
        statusDisplay: json['status_display']?.toString() ?? 'New',
        assignedAgent: json['assigned_agent'] != null 
            ? User.fromJson(json['assigned_agent']) 
            : null,
        source: json['source']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'].toString())
            : DateTime.now(),
        callCount: json['call_count'] ?? 0,
        lastCallDate: json['last_call_date'] != null 
            ? DateTime.parse(json['last_call_date'].toString()) 
            : null,
        lastCallDisposition: json['last_call_disposition']?.toString(),
        followUpCount: json['follow_up_count'] ?? 0,
      );
    } catch (e) {
      print('Error parsing Lead from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Get status color for UI
  Color getStatusColor() {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'interested':
        return Colors.green;
      case 'not_interested':
        return Colors.red;
      case 'callback':
        return Colors.purple;
      case 'wrong_number':
        return Colors.grey;
      case 'not_reachable':
        return Colors.brown;
      case 'converted':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData getStatusIcon() {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'contacted':
        return Icons.phone;
      case 'interested':
        return Icons.thumb_up;
      case 'not_interested':
        return Icons.thumb_down;
      case 'callback':
        return Icons.schedule;
      case 'wrong_number':
        return Icons.error;
      case 'not_reachable':
        return Icons.phone_disabled;
      case 'converted':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

// Dashboard data model
class DashboardData {
  final DashboardSummary summary;
  final List<LeadStatusCount> leadStatuses;
  final List<CallLog> recentCalls;
  final List<FollowUp> upcomingFollowUps;

  DashboardData({
    required this.summary,
    required this.leadStatuses,
    required this.recentCalls,
    required this.upcomingFollowUps,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      leadStatuses: (json['lead_statuses'] as List? ?? [])
          .map((item) => LeadStatusCount.fromJson(item))
          .toList(),
      recentCalls: (json['recent_calls'] as List? ?? [])
          .map((item) => CallLog.fromJson(item))
          .toList(),
      upcomingFollowUps: (json['upcoming_follow_ups'] as List? ?? [])
          .map((item) => FollowUp.fromJson(item))
          .toList(),
    );
  }
}

class DashboardSummary {
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int convertedLeads;
  final double conversionRate;
  final int todayCalls;
  final int todayFollowUps;
  final int weekCalls;

  DashboardSummary({
    required this.totalLeads,
    required this.newLeads,
    required this.contactedLeads,
    required this.convertedLeads,
    required this.conversionRate,
    required this.todayCalls,
    required this.todayFollowUps,
    required this.weekCalls,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalLeads: json['total_leads'] ?? 0,
      newLeads: json['new_leads'] ?? 0,
      contactedLeads: json['contacted_leads'] ?? 0,
      convertedLeads: json['converted_leads'] ?? 0,
      conversionRate: (json['conversion_rate'] ?? 0.0).toDouble(),
      todayCalls: json['today_calls'] ?? 0,
      todayFollowUps: json['today_follow_ups'] ?? 0,
      weekCalls: json['week_calls'] ?? 0,
    );
  }
}

class LeadStatusCount {
  final String status;
  final int count;

  LeadStatusCount({
    required this.status,
    required this.count,
  });

  factory LeadStatusCount.fromJson(Map<String, dynamic> json) {
    return LeadStatusCount(
      status: json['status']?.toString() ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CallLog {
  final int id;
  final String leadName;
  final String phone;
  final DateTime callDate;
  final String disposition;
  final String? remarks;

  CallLog({
    required this.id,
    required this.leadName,
    required this.phone,
    required this.callDate,
    required this.disposition,
    this.remarks,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] ?? 0,
      leadName: json['lead']?['name']?.toString() ?? '',
      phone: json['lead']?['phone']?.toString() ?? '',
      callDate: json['call_date'] != null 
          ? DateTime.parse(json['call_date'].toString())
          : DateTime.now(),
      disposition: json['disposition_display']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
    );
  }
}

class FollowUp {
  final int id;
  final String leadName;
  final String phone;
  final DateTime followUpDate;
  final String? remarks;

  FollowUp({
    required this.id,
    required this.leadName,
    required this.phone,
    required this.followUpDate,
    this.remarks,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'] ?? 0,
      leadName: json['lead']?['name']?.toString() ?? '',
      phone: json['lead']?['phone']?.toString() ?? '',
      followUpDate: json['follow_up_date'] != null 
          ? DateTime.parse(json['follow_up_date'].toString())
          : DateTime.now(),
      remarks: json['remarks']?.toString(),
    );
  }
}