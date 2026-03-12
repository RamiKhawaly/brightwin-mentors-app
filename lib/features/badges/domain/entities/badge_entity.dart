import 'package:equatable/equatable.dart';

enum BadgeType {
  helpfulMentor,
  interviewExpert,
  careerGuide,
  topReferrer,
  quickResponder,
  dedicatedMentor,
  goldMentor,
  silverMentor,
  bronzeMentor,
}

enum BadgeCategory {
  engagement,
  achievement,
  milestone,
}

class BadgeEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final BadgeCategory category;
  final String iconUrl;
  final int requiredPoints;
  final DateTime? earnedAt;
  final bool isEarned;
  final int currentProgress;

  const BadgeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.iconUrl,
    required this.requiredPoints,
    this.earnedAt,
    required this.isEarned,
    this.currentProgress = 0,
  });

  double get progressPercentage {
    if (requiredPoints == 0) return 0;
    return (currentProgress / requiredPoints).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        category,
        iconUrl,
        requiredPoints,
        earnedAt,
        isEarned,
        currentProgress,
      ];
}
