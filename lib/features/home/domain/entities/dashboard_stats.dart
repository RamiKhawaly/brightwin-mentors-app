import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int activeJobs;
  final int jobSubmissions;
  final int badges;
  final int sessions;
  final double earnings;
  final List<UpcomingActivity> upcomingActivities;
  final String subscriptionPlan;
  final String subscriptionStatus;

  const DashboardStats({
    required this.activeJobs,
    required this.jobSubmissions,
    required this.badges,
    required this.sessions,
    required this.earnings,
    required this.upcomingActivities,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      activeJobs: 0,
      jobSubmissions: 0,
      badges: 0,
      sessions: 0,
      earnings: 0.0,
      upcomingActivities: [],
      subscriptionPlan: 'Mentor Plan',
      subscriptionStatus: 'ACTIVE',
    );
  }

  @override
  List<Object?> get props => [
        activeJobs,
        jobSubmissions,
        badges,
        sessions,
        earnings,
        upcomingActivities,
        subscriptionPlan,
        subscriptionStatus,
      ];
}

class UpcomingActivity extends Equatable {
  final String id;
  final String type; // 'interview', 'phone_call', 'chat'
  final String title;
  final String jobSeekerName;
  final DateTime scheduledAt;
  final String? notes;

  const UpcomingActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.jobSeekerName,
    required this.scheduledAt,
    this.notes,
  });

  String get activityIcon {
    switch (type) {
      case 'interview':
        return '🎯';
      case 'phone_call':
        return '📞';
      case 'chat':
        return '💬';
      default:
        return '📅';
    }
  }

  String get activityTypeName {
    switch (type) {
      case 'interview':
        return 'Interview Simulation';
      case 'phone_call':
        return 'Phone Call';
      case 'chat':
        return 'Chat Session';
      default:
        return 'Activity';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        jobSeekerName,
        scheduledAt,
        notes,
      ];
}
