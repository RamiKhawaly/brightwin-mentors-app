import '../../../../core/network/dio_client.dart';
import '../models/session_model.dart';
import '../models/propose_slots_request.dart';
import '../models/complete_session_request.dart';
import '../models/reschedule_request.dart';
import '../models/session_attendance_model.dart';
import '../models/session_participant_event_model.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_attendance.dart';
import '../../domain/entities/session_participant_event.dart';

class SessionsRepository {
  final DioClient _dioClient;

  SessionsRepository(this._dioClient);

  /// POST /api/mentorship/sessions/{id}/propose-slots - Propose 1-3 time slots
  Future<Session> proposeTimeSlots(String sessionId, ProposeSlotsRequest request) async {
    try {
      print('Proposing time slots for session: $sessionId');
      final response = await _dioClient.dio.post(
        '/api/mentorship/sessions/$sessionId/propose-slots',
        data: request.toJson(),
      );

      final model = SessionModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error proposing time slots: $e');
      rethrow;
    }
  }

  /// PUT /api/mentorship/sessions/{id}/cancel/mentor - Cancel session
  Future<void> cancelSession(String sessionId, String reason) async {
    try {
      print('Cancelling session: $sessionId');
      await _dioClient.dio.put(
        '/api/mentorship/sessions/$sessionId/cancel/mentor',
        data: {'reason': reason},
      );
    } catch (e) {
      print('❌ Error cancelling session: $e');
      rethrow;
    }
  }

  /// PUT /api/mentorship/sessions/{id}/reschedule/mentor - Reschedule session
  Future<Session> rescheduleSession(String sessionId, RescheduleRequest request) async {
    try {
      print('Rescheduling session: $sessionId');
      final response = await _dioClient.dio.put(
        '/api/mentorship/sessions/$sessionId/reschedule/mentor',
        data: request.toJson(),
      );

      final model = SessionModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error rescheduling session: $e');
      rethrow;
    }
  }

  /// PUT /api/mentorship/sessions/{id}/complete - Complete with feedback
  Future<void> completeSession(String sessionId, CompleteSessionRequest request) async {
    try {
      print('Completing session: $sessionId');
      await _dioClient.dio.put(
        '/api/mentorship/sessions/$sessionId/complete',
        data: request.toJson(),
      );
    } catch (e) {
      print('❌ Error completing session: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/mentor/my - Get my sessions (filter by status)
  Future<List<Session>> getMySessions({String? status}) async {
    try {
      print('📡 Fetching my sessions${status != null ? ' with status: $status' : ''}');
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/mentor/my',
        queryParameters: status != null ? {'status': status} : null,
      );

      print('✅ Response received: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['sessions'] ?? response.data['data'] ?? []);

      print('✅ Parsed ${data.length} sessions');
      return data.map((json) => SessionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      print('❌ Error fetching my sessions: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/mentor/pending - Get pending requests
  /// Includes PENDING, AWAITING_SEEKER_RESPONSE, and NEGOTIATING sessions
  Future<List<Session>> getPendingRequests() async {
    try {
      print('📡 Fetching pending session requests');

      // Fetch all sessions and filter by status
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/mentor/my',
      );

      print('✅ Response received: ${response.statusCode}');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['sessions'] ?? response.data['data'] ?? []);

      // Filter for pending statuses
      final pendingStatuses = ['PENDING', 'AWAITING_SEEKER_RESPONSE', 'NEGOTIATING'];
      final sessions = data
          .map((json) => SessionModel.fromJson(json))
          .where((model) => pendingStatuses.contains(model.status.toUpperCase()))
          .map((model) => model.toEntity())
          .toList();

      print('✅ Parsed ${sessions.length} pending sessions');
      return sessions;
    } catch (e) {
      print('❌ Error fetching pending requests: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/mentor/negotiating - Get sessions needing new proposals
  Future<List<Session>> getNegotiatingSessions() async {
    try {
      print('📡 Fetching negotiating sessions');
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/mentor/negotiating',
      );

      print('✅ Response received: ${response.statusCode}');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['sessions'] ?? response.data['data'] ?? []);

      print('✅ Parsed ${data.length} negotiating sessions');
      return data.map((json) => SessionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      print('❌ Error fetching negotiating sessions: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/mentor/upcoming - Get upcoming sessions
  /// Only includes CONFIRMED sessions with scheduled dates
  Future<List<Session>> getUpcomingSessions() async {
    try {
      print('📡 Fetching upcoming sessions');

      // Fetch all sessions and filter for confirmed ones
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/mentor/my',
      );

      print('✅ Response received: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['sessions'] ?? response.data['data'] ?? []);

      // Filter for confirmed sessions only
      final sessions = data
          .map((json) => SessionModel.fromJson(json))
          .where((model) => model.status.toUpperCase() == 'CONFIRMED')
          .map((model) => model.toEntity())
          .toList();

      print('✅ Parsed ${sessions.length} upcoming sessions');
      return sessions;
    } catch (e) {
      print('❌ Error fetching upcoming sessions: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/{id} - Get session details (includes all proposed time slots)
  Future<Session> getSessionDetails(String sessionId) async {
    try {
      print('📡 Fetching session details: $sessionId');
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/$sessionId',
      );

      print('✅ Session details received');
      final model = SessionModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error fetching session details: $e');
      rethrow;
    }
  }

  /// GET /api/mentorship/sessions/{id}/participant-events - Get session participant events
  /// Returns chronological list of join/leave events for attendance tracking
  Future<List<SessionParticipantEvent>> getSessionParticipantEvents(String sessionId) async {
    try {
      print('📡 Fetching session participant events: $sessionId');
      final response = await _dioClient.dio.get(
        '/api/mentorship/sessions/$sessionId/participant-events',
      );

      print('✅ Session participant events received');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['events'] ?? response.data['data'] ?? []);

      final events = data
          .map((json) => SessionParticipantEventModel.fromJson(json).toEntity())
          .toList();

      // Sort by event time (most recent first for easy access to current state)
      events.sort((a, b) => b.eventTime.compareTo(a.eventTime));

      return events;
    } catch (e) {
      print('❌ Error fetching session participant events: $e');
      rethrow;
    }
  }

  /// Derive attendance from participant events
  /// For confirmed sessions, calculates who is currently attending based on JOINED/LEFT events
  SessionAttendance deriveAttendance(String sessionId, List<SessionParticipantEvent> events) {
    // Group events by participant
    final Map<String, List<SessionParticipantEvent>> eventsByParticipant = {};
    for (final event in events) {
      final key = event.participantId ?? event.participantName;
      eventsByParticipant.putIfAbsent(key, () => []);
      eventsByParticipant[key]!.add(event);
    }

    final List<SessionParticipant> participants = [];
    int presentCount = 0;
    int absentCount = 0;

    eventsByParticipant.forEach((key, participantEvents) {
      // Sort events by time (most recent first)
      participantEvents.sort((a, b) => b.eventTime.compareTo(a.eventTime));

      final latestEvent = participantEvents.first;
      final joinEvent = participantEvents.lastWhere(
        (e) => e.eventType == ParticipantEventType.joined,
        orElse: () => participantEvents.first,
      );
      final leaveEvent = participantEvents.firstWhere(
        (e) => e.eventType == ParticipantEventType.left,
        orElse: () => participantEvents.first,
      );

      // Determine current status based on most recent event
      AttendanceStatus status;
      DateTime? joinedAt;
      DateTime? leftAt;
      int? durationMinutes;

      if (latestEvent.eventType == ParticipantEventType.joined) {
        status = AttendanceStatus.inProgress;
        joinedAt = joinEvent.eventTime;
        presentCount++;
      } else if (latestEvent.eventType == ParticipantEventType.joinedLobby) {
        status = AttendanceStatus.waiting;
        presentCount++;
      } else if (latestEvent.eventType == ParticipantEventType.left ||
                 latestEvent.eventType == ParticipantEventType.leftLobby) {
        // Check if they ever joined
        if (participantEvents.any((e) => e.eventType == ParticipantEventType.joined)) {
          status = AttendanceStatus.completed;
          joinedAt = joinEvent.eventTime;
          leftAt = leaveEvent.eventTime;
          if (joinedAt != null && leftAt != null) {
            durationMinutes = leftAt.difference(joinedAt).inMinutes;
          }
        } else {
          status = AttendanceStatus.notStarted;
          absentCount++;
        }
      } else {
        status = AttendanceStatus.notStarted;
        absentCount++;
      }

      participants.add(
        SessionParticipant(
          id: latestEvent.id,
          participantId: latestEvent.userId ?? latestEvent.participantId ?? key,
          participantName: latestEvent.participantName,
          participantAvatar: null, // Not provided in events
          participantType: latestEvent.participantType,
          status: status,
          joinedAt: joinedAt,
          leftAt: leftAt,
          durationMinutes: durationMinutes,
        ),
      );
    });

    return SessionAttendance(
      sessionId: sessionId,
      participants: participants,
      totalParticipants: participants.length,
      presentCount: presentCount,
      absentCount: absentCount,
    );
  }
}
