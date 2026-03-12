import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/session_attendance.dart';

class SessionParticipantModel {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String participantType;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? durationMinutes;

  SessionParticipantModel({
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

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) {
    return SessionParticipantModel(
      id: json['id']?.toString() ?? '',
      participantId: json['participantId']?.toString() ?? json['userId']?.toString() ?? '',
      participantName: json['participantName'] ?? json['userName'] ?? 'Unknown',
      participantAvatar: json['participantAvatar'] ?? json['userAvatar'],
      participantType: json['participantType'] ?? json['userType'] ?? 'JOB_SEEKER',
      status: json['status'] ?? 'NOT_STARTED',
      joinedAt: json['joinedAt'] != null ? parseServerDateTime(json['joinedAt']) : null,
      leftAt: json['leftAt'] != null ? parseServerDateTime(json['leftAt']) : null,
      durationMinutes: json['durationMinutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      if (participantAvatar != null) 'participantAvatar': participantAvatar,
      'participantType': participantType,
      'status': status,
      if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
      if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    };
  }

  SessionParticipant toEntity() {
    return SessionParticipant(
      id: id,
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      participantType: participantType,
      status: _parseAttendanceStatus(status),
      joinedAt: joinedAt,
      leftAt: leftAt,
      durationMinutes: durationMinutes,
    );
  }

  AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status.toUpperCase()) {
      case 'NOT_STARTED':
        return AttendanceStatus.notStarted;
      case 'WAITING':
        return AttendanceStatus.waiting;
      case 'IN_PROGRESS':
      case 'ATTENDING':
        return AttendanceStatus.inProgress;
      case 'COMPLETED':
        return AttendanceStatus.completed;
      case 'NO_SHOW':
        return AttendanceStatus.noShow;
      default:
        return AttendanceStatus.notStarted;
    }
  }
}

class SessionAttendanceModel {
  final String sessionId;
  final List<SessionParticipantModel> participants;
  final int totalParticipants;
  final int presentCount;
  final int absentCount;

  SessionAttendanceModel({
    required this.sessionId,
    required this.participants,
    required this.totalParticipants,
    required this.presentCount,
    required this.absentCount,
  });

  factory SessionAttendanceModel.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    final participants = participantsList
        .map((p) => SessionParticipantModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return SessionAttendanceModel(
      sessionId: json['sessionId']?.toString() ?? '',
      participants: participants,
      totalParticipants: json['totalParticipants'] ?? participants.length,
      presentCount: json['presentCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'totalParticipants': totalParticipants,
      'presentCount': presentCount,
      'absentCount': absentCount,
    };
  }

  SessionAttendance toEntity() {
    return SessionAttendance(
      sessionId: sessionId,
      participants: participants.map((p) => p.toEntity()).toList(),
      totalParticipants: totalParticipants,
      presentCount: presentCount,
      absentCount: absentCount,
    );
  }
}
