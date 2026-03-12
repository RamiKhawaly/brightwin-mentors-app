import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.activeJobs,
    required super.jobSubmissions,
    required super.badges,
    required super.sessions,
    required super.earnings,
    required super.upcomingActivities,
    required super.subscriptionPlan,
    required super.subscriptionStatus,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final activitiesList = json['upcomingActivities'] as List<dynamic>? ?? [];
    final activities = activitiesList
        .map((activity) => UpcomingActivityModel.fromJson(activity as Map<String, dynamic>))
        .toList();

    return DashboardStatsModel(
      activeJobs: json['activeJobs'] ?? 0,
      jobSubmissions: json['jobSubmissions'] ?? 0,
      badges: json['badges'] ?? 0,
      sessions: json['sessions'] ?? 0,
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      upcomingActivities: activities,
      subscriptionPlan: json['subscriptionPlan'] ?? 'Mentor Plan',
      subscriptionStatus: json['subscriptionStatus'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeJobs': activeJobs,
      'jobSubmissions': jobSubmissions,
      'badges': badges,
      'sessions': sessions,
      'earnings': earnings,
      'upcomingActivities': upcomingActivities
          .map((activity) => UpcomingActivityModel.fromEntity(activity).toJson())
          .toList(),
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStatus': subscriptionStatus,
    };
  }
}

class UpcomingActivityModel extends UpcomingActivity {
  const UpcomingActivityModel({
    required super.id,
    required super.type,
    required super.title,
    required super.jobSeekerName,
    required super.scheduledAt,
    super.notes,
  });

  factory UpcomingActivityModel.fromJson(Map<String, dynamic> json) {
    return UpcomingActivityModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      jobSeekerName: json['jobSeekerName'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  factory UpcomingActivityModel.fromEntity(UpcomingActivity entity) {
    return UpcomingActivityModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      jobSeekerName: entity.jobSeekerName,
      scheduledAt: entity.scheduledAt,
      notes: entity.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'jobSeekerName': jobSeekerName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'notes': notes,
    };
  }
}
