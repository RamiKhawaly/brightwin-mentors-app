import 'package:equatable/equatable.dart';

enum FeedbackType {
  interviewPerformance,
  technicalSkills,
  communicationSkills,
  overall,
}

class FeedbackEntity extends Equatable {
  final String id;
  final String mentorId;
  final String jobSeekerId;
  final String jobSeekerName;
  final FeedbackType type;
  final int rating; // 1-5 stars
  final String comments;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final DateTime createdAt;
  final bool isPublic;

  const FeedbackEntity({
    required this.id,
    required this.mentorId,
    required this.jobSeekerId,
    required this.jobSeekerName,
    required this.type,
    required this.rating,
    required this.comments,
    required this.strengths,
    required this.areasForImprovement,
    required this.createdAt,
    this.isPublic = true,
  });

  @override
  List<Object?> get props => [
        id,
        mentorId,
        jobSeekerId,
        jobSeekerName,
        type,
        rating,
        comments,
        strengths,
        areasForImprovement,
        createdAt,
        isPublic,
      ];

  String get typeName {
    switch (type) {
      case FeedbackType.interviewPerformance:
        return 'Interview Performance';
      case FeedbackType.technicalSkills:
        return 'Technical Skills';
      case FeedbackType.communicationSkills:
        return 'Communication Skills';
      case FeedbackType.overall:
        return 'Overall Assessment';
    }
  }
}
