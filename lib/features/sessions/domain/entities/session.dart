import 'package:equatable/equatable.dart';

enum SessionType {
  call,
  simulation,
  chat;

  String get displayName {
    switch (this) {
      case SessionType.call:
        return 'Phone Call';
      case SessionType.simulation:
        return 'Interview Simulation';
      case SessionType.chat:
        return 'Chat Session';
    }
  }

  String get icon {
    switch (this) {
      case SessionType.call:
        return '📞';
      case SessionType.simulation:
        return '🎯';
      case SessionType.chat:
        return '💬';
    }
  }
}

enum SessionStatus {
  pending,
  awaitingSeekerResponse,
  negotiating,
  confirmed,
  cancelledByMentor,
  cancelledBySeeker,
  cancelledNoAgreement,
  rescheduled,
  completed,
  noShowMentor,
  noShowSeeker;

  String get displayName {
    switch (this) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.awaitingSeekerResponse:
        return 'Awaiting Response';
      case SessionStatus.negotiating:
        return 'Negotiating';
      case SessionStatus.confirmed:
        return 'Confirmed';
      case SessionStatus.cancelledByMentor:
        return 'Cancelled by Mentor';
      case SessionStatus.cancelledBySeeker:
        return 'Cancelled by Seeker';
      case SessionStatus.cancelledNoAgreement:
        return 'Cancelled - No Agreement';
      case SessionStatus.rescheduled:
        return 'Rescheduled';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.noShowMentor:
        return 'No Show - Mentor';
      case SessionStatus.noShowSeeker:
        return 'No Show - Seeker';
    }
  }
}

class TimeSlot extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String? proposedBy;
  final bool isSelected;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.proposedBy,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [id, startTime, endTime, proposedBy, isSelected];
}

class Session extends Equatable {
  final String id;
  final SessionType type;
  final SessionStatus status;
  final String jobSeekerId;
  final String jobSeekerName;
  final String? jobSeekerAvatar;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String? notes;
  final String? topic;
  final List<TimeSlot>? proposedTimeSlots;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? feedbackId;
  final int? jobId;
  final String? meetingLink;

  const Session({
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

  @override
  List<Object?> get props => [
        id,
        type,
        status,
        jobSeekerId,
        jobSeekerName,
        jobSeekerAvatar,
        scheduledAt,
        durationMinutes,
        notes,
        topic,
        proposedTimeSlots,
        createdAt,
        completedAt,
        feedbackId,
        jobId,
        meetingLink,
      ];
}
