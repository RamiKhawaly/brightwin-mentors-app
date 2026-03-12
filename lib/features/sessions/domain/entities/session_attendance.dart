import 'package:equatable/equatable.dart';

enum AttendanceStatus {
  notStarted,
  waiting,
  inProgress,
  completed,
  noShow;

  String get displayName {
    switch (this) {
      case AttendanceStatus.notStarted:
        return 'Not Started';
      case AttendanceStatus.waiting:
        return 'Waiting';
      case AttendanceStatus.inProgress:
        return 'In Progress';
      case AttendanceStatus.completed:
        return 'Completed';
      case AttendanceStatus.noShow:
        return 'No Show';
    }
  }
}

class SessionParticipant extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String participantType; // 'MENTOR' or 'JOB_SEEKER'
  final AttendanceStatus status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? durationMinutes;

  const SessionParticipant({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.participantType,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.durationMinutes,
  });

  bool get isAttending => status == AttendanceStatus.inProgress || status == AttendanceStatus.waiting;

  bool get hasJoined => joinedAt != null;

  @override
  List<Object?> get props => [
        id,
        participantId,
        participantName,
        participantAvatar,
        participantType,
        status,
        joinedAt,
        leftAt,
        durationMinutes,
      ];
}

class SessionAttendance extends Equatable {
  final String sessionId;
  final List<SessionParticipant> participants;
  final int totalParticipants;
  final int presentCount;
  final int absentCount;

  const SessionAttendance({
    required this.sessionId,
    required this.participants,
    required this.totalParticipants,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props => [
        sessionId,
        participants,
        totalParticipants,
        presentCount,
        absentCount,
      ];
}
