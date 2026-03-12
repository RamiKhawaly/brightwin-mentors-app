import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/session.dart';
import 'time_slot_model.dart';

class SessionModel {
  final String id;
  final String type;
  final String status;
  final String jobSeekerId;
  final String jobSeekerName;
  final String? jobSeekerAvatar;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String? notes;
  final String? topic;
  final List<TimeSlotModel>? proposedTimeSlots;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? feedbackId;
  final int? jobId;
  final String? meetingLink;

  SessionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.jobSeekerId,
    required this.jobSeekerName,
    this.jobSeekerAvatar,
    this.scheduledAt,
    required this.durationMinutes,
    this.notes,
    this.topic,
    this.proposedTimeSlots,
    required this.createdAt,
    this.completedAt,
    this.feedbackId,
    this.jobId,
    this.meetingLink,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id']?.toString() ?? '',
      type: json['serviceType'] ?? json['type'] ?? 'CALL',
      status: json['status'] ?? 'PENDING',
      jobSeekerId: json['jobSeekerId']?.toString() ?? json['userId']?.toString() ?? '',
      jobSeekerName: json['jobSeekerName'] ?? json['userName'] ?? 'Unknown',
      jobSeekerAvatar: json['jobSeekerAvatar'] ?? json['userAvatar'],
      scheduledAt: json['scheduledDate'] != null
          ? parseServerDateTime(json['scheduledDate'])
          : (json['scheduledAt'] != null ? parseServerDateTime(json['scheduledAt']) : null),
      durationMinutes: json['durationMinutes'] ?? 60,
      notes: json['notes'] ?? json['requestMessage'],
      topic: json['topic'] ?? json['jobTitle'],
      proposedTimeSlots: json['proposedTimeSlots'] != null && (json['proposedTimeSlots'] as List).isNotEmpty
          ? (json['proposedTimeSlots'] as List)
              .map((slot) => TimeSlotModel.fromJson(slot))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? parseServerDateTime(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? parseServerDateTime(json['completedAt'])
          : null,
      feedbackId: json['feedbackId']?.toString(),
      jobId: json['jobId'] as int? ?? json['jobPostingId'] as int?,
      meetingLink: json['meetingLink'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'jobSeekerId': jobSeekerId,
      'jobSeekerName': jobSeekerName,
      if (jobSeekerAvatar != null) 'jobSeekerAvatar': jobSeekerAvatar,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      'durationMinutes': durationMinutes,
      if (notes != null) 'notes': notes,
      if (topic != null) 'topic': topic,
      if (proposedTimeSlots != null)
        'proposedTimeSlots': proposedTimeSlots!.map((slot) => slot.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (feedbackId != null) 'feedbackId': feedbackId,
      if (jobId != null) 'jobId': jobId,
      if (meetingLink != null) 'meetingLink': meetingLink,
    };
  }

  Session toEntity() {
    return Session(
      id: id,
      type: _parseSessionType(type),
      status: _parseSessionStatus(status),
      jobSeekerId: jobSeekerId,
      jobSeekerName: jobSeekerName,
      jobSeekerAvatar: jobSeekerAvatar,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      notes: notes,
      topic: topic,
      proposedTimeSlots: proposedTimeSlots?.map((slot) => slot.toEntity()).toList(),
      createdAt: createdAt,
      completedAt: completedAt,
      feedbackId: feedbackId,
      jobId: jobId,
      meetingLink: meetingLink,
    );
  }

  SessionType _parseSessionType(String type) {
    switch (type.toUpperCase()) {
      case 'CALL':
      case 'PHONE_CALL':
        return SessionType.call;
      case 'SIMULATION':
      case 'MOCK_INTERVIEW':
      case 'INTERVIEW_SIMULATION':
        return SessionType.simulation;
      case 'CHAT':
      case 'CHAT_SESSION':
        return SessionType.chat;
      default:
        return SessionType.call;
    }
  }

  SessionStatus _parseSessionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return SessionStatus.pending;
      case 'AWAITING_SEEKER_RESPONSE':
        return SessionStatus.awaitingSeekerResponse;
      case 'NEGOTIATING':
        return SessionStatus.negotiating;
      case 'CONFIRMED':
        return SessionStatus.confirmed;
      case 'CANCELLED_BY_MENTOR':
        return SessionStatus.cancelledByMentor;
      case 'CANCELLED_BY_SEEKER':
        return SessionStatus.cancelledBySeeker;
      case 'CANCELLED_NO_AGREEMENT':
        return SessionStatus.cancelledNoAgreement;
      case 'RESCHEDULED':
        return SessionStatus.rescheduled;
      case 'COMPLETED':
        return SessionStatus.completed;
      case 'NO_SHOW_MENTOR':
        return SessionStatus.noShowMentor;
      case 'NO_SHOW_SEEKER':
        return SessionStatus.noShowSeeker;
      default:
        return SessionStatus.pending;
    }
  }
}
