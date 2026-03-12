import 'package:equatable/equatable.dart';

enum ParticipantEventType {
  joined,
  left,
  joinedLobby,
  leftLobby;

  String get displayName {
    switch (this) {
      case ParticipantEventType.joined:
        return 'Joined Session';
      case ParticipantEventType.left:
        return 'Left Session';
      case ParticipantEventType.joinedLobby:
        return 'Joined Lobby';
      case ParticipantEventType.leftLobby:
        return 'Left Lobby';
    }
  }

  String get icon {
    switch (this) {
      case ParticipantEventType.joined:
        return '✅';
      case ParticipantEventType.left:
        return '❌';
      case ParticipantEventType.joinedLobby:
        return '🚪';
      case ParticipantEventType.leftLobby:
        return '🚶';
    }
  }
}

class SessionParticipantEvent extends Equatable {
  final String id;
  final String sessionId;
  final String? userId; // Nullable - might not be a registered user
  final String participantName;
  final String? participantEmail;
  final String? participantId; // Jitsi participant ID
  final ParticipantEventType eventType;
  final DateTime eventTime;
  final bool? isModerator;
  final String? disconnectReason;
  final bool isMentor;
  final bool isJobSeeker;

  const SessionParticipantEvent({
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

  String get participantType {
    if (isMentor) return 'MENTOR';
    if (isJobSeeker) return 'JOB_SEEKER';
    return 'GUEST';
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        userId,
        participantName,
        participantEmail,
        participantId,
        eventType,
        eventTime,
        isModerator,
        disconnectReason,
        isMentor,
        isJobSeeker,
      ];
}
