import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/feedback_entity.dart';

class FeedbackModel {
  final String id;
  final String mentorId;
  final String jobSeekerId;
  final String jobSeekerName;
  final String type;
  final int rating;
  final String comments;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final DateTime createdAt;
  final bool isPublic;

  FeedbackModel({
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
    required this.isPublic,
  });

  // Convert from JSON
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? json['_id'] ?? '',
      mentorId: json['mentorId'] ?? '',
      jobSeekerId: json['jobSeekerId'] ?? '',
      jobSeekerName: json['jobSeekerName'] ?? '',
      type: json['type'] ?? 'overall',
      rating: json['rating'] ?? 0,
      comments: json['comments'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement: List<String>.from(json['areasForImprovement'] ?? []),
      createdAt: json['createdAt'] != null
          ? parseServerDateTime(json['createdAt'])
          : DateTime.now(),
      isPublic: json['isPublic'] ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentorId': mentorId,
      'jobSeekerId': jobSeekerId,
      'jobSeekerName': jobSeekerName,
      'type': type,
      'rating': rating,
      'comments': comments,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  // Convert to domain entity
  FeedbackEntity toEntity() {
    return FeedbackEntity(
      id: id,
      mentorId: mentorId,
      jobSeekerId: jobSeekerId,
      jobSeekerName: jobSeekerName,
      type: _parseFeedbackType(type),
      rating: rating,
      comments: comments,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      createdAt: createdAt,
      isPublic: isPublic,
    );
  }

  // Convert from domain entity
  factory FeedbackModel.fromEntity(FeedbackEntity entity) {
    return FeedbackModel(
      id: entity.id,
      mentorId: entity.mentorId,
      jobSeekerId: entity.jobSeekerId,
      jobSeekerName: entity.jobSeekerName,
      type: _feedbackTypeToString(entity.type),
      rating: entity.rating,
      comments: entity.comments,
      strengths: entity.strengths,
      areasForImprovement: entity.areasForImprovement,
      createdAt: entity.createdAt,
      isPublic: entity.isPublic,
    );
  }

  // Parse feedback type from string
  static FeedbackType _parseFeedbackType(String type) {
    switch (type.toLowerCase()) {
      case 'interviewperformance':
      case 'interview_performance':
        return FeedbackType.interviewPerformance;
      case 'technicalskills':
      case 'technical_skills':
        return FeedbackType.technicalSkills;
      case 'communicationskills':
      case 'communication_skills':
        return FeedbackType.communicationSkills;
      case 'overall':
      default:
        return FeedbackType.overall;
    }
  }

  // Convert feedback type to string
  static String _feedbackTypeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.interviewPerformance:
        return 'interviewPerformance';
      case FeedbackType.technicalSkills:
        return 'technicalSkills';
      case FeedbackType.communicationSkills:
        return 'communicationSkills';
      case FeedbackType.overall:
        return 'overall';
    }
  }
}
