// lib/models/dashboard_model.dart
import 'call_log_model.dart';
import 'follow_up_model.dart';

class DashboardData {
  final DashboardSummary summary;
  final List<LeadStatusCount> leadStatuses;
  final List<CallLog> recentCalls;
  final List<FollowUp> upcomingFollowUps;
  final MonthlyTarget? monthlyTargets;

  DashboardData({
    required this.summary,
    required this.leadStatuses,
    required this.recentCalls,
    required this.upcomingFollowUps,
    this.monthlyTargets,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary']),
      leadStatuses: (json['lead_statuses'] as List)
          .map((item) => LeadStatusCount.fromJson(item))
          .toList(),
      recentCalls: (json['recent_calls'] as List)
          .map((item) => CallLog.fromJson(item))
          .toList(),
      upcomingFollowUps: (json['upcoming_follow_ups'] as List)
          .map((item) => FollowUp.fromJson(item))
          .toList(),
      monthlyTargets: json['monthly_targets'] != null
          ? MonthlyTarget.fromJson(json['monthly_targets'])
          : null,
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
      status: json['status'],
      count: json['count'],
    );
  }
}

class MonthlyTarget {
  final int targetCalls;
  final int actualCalls;
  final int targetConversions;
  final int actualConversions;
  final double callsPercentage;
  final double conversionsPercentage;

  MonthlyTarget({
    required this.targetCalls,
    required this.actualCalls,
    required this.targetConversions,
    required this.actualConversions,
    required this.callsPercentage,
    required this.conversionsPercentage,
  });

  factory MonthlyTarget.fromJson(Map<String, dynamic> json) {
    return MonthlyTarget(
      targetCalls: json['target_calls'] ?? 0,
      actualCalls: json['actual_calls'] ?? 0,
      targetConversions: json['target_conversions'] ?? 0,
      actualConversions: json['actual_conversions'] ?? 0,
      callsPercentage: (json['calls_percentage'] ?? 0.0).toDouble(),
      conversionsPercentage: (json['conversions_percentage'] ?? 0.0).toDouble(),
    );
  }
}