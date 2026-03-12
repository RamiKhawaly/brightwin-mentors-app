import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/session_participant_event.dart';

class SessionParticipantEventModel {
  final String id;
  final String sessionId;
  final String? userId;
  final String participantName;
  final String? participantEmail;
  final String? participantId;
  final String eventType;
  final DateTime eventTime;
  final bool? isModerator;
  final String? disconnectReason;
  final bool isMentor;
  final bool isJobSeeker;

  SessionParticipantEventModel({
    required this.id,
    required this.sessionId,
    this.userId,
    required this.participantName,
    this.participantEmail,
    this.participantId,
    required this.eventType,
    required this.eventTime,
    this.isModerator,
    this.disconnectReason,
    required this.isMentor,
    required this.isJobSeeker,
  });

  factory SessionParticipantEventModel.fromJson(Map<String, dynamic> json) {
    return SessionParticipantEventModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      participantName: json['participantName'] ?? 'Unknown',
      participantEmail: json['participantEmail'],
      participantId: json['participantId'],
      eventType: json['eventType'] ?? 'JOINED',
      eventTime: json['eventTime'] != null
          ? parseServerDateTime(json['eventTime'])
          : DateTime.now(),
      isModerator: json['isModerator'] as bool?,
      disconnectReason: json['disconnectReason'],
      isMentor: json['isMentor'] ?? false,
      isJobSeeker: json['isJobSeeker'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      if (userId != null) 'userId': userId,
      'participantName': participantName,
      if (participantEmail != null) 'participantEmail': participantEmail,
      if (participantId != null) 'participantId': participantId,
      'eventType': eventType,
      'eventTime': eventTime.toIso8601String(),
      if (isModerator != null) 'isModerator': isModerator,
      if (disconnectReason != null) 'disconnectReason': disconnectReason,
      'isMentor': isMentor,
      'isJobSeeker': isJobSeeker,
    };
  }

  SessionParticipantEvent toEntity() {
    return SessionParticipantEvent(
      id: id,
      sessionId: sessionId,
      userId: userId,
      participantName: participantName,
      participantEmail: participantEmail,
      participantId: participantId,
      eventType: _parseEventType(eventType),
      eventTime: eventTime,
      isModerator: isModerator,
      disconnectReason: disconnectReason,
      isMentor: isMentor,
      isJobSeeker: isJobSeeker,
    );
  }

  ParticipantEventType _parseEventType(String type) {
    switch (type.toUpperCase()) {
      case 'JOINED':
        return ParticipantEventType.joined;
      case 'LEFT':
        return ParticipantEventType.left;
      case 'JOINED_LOBBY':
        return ParticipantEventType.joinedLobby;
      case 'LEFT_LOBBY':
        return ParticipantEventType.leftLobby;
      default:
        return ParticipantEventType.joined;
    }
  }
}
