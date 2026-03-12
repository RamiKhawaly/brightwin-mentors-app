import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/session_attendance.dart';
import '../../domain/entities/session_participant_event.dart';

class ParticipantHistoryDialog extends StatelessWidget {
  final SessionAttendance attendance;
  final List<SessionParticipantEvent> allEvents;

  const ParticipantHistoryDialog({
    super.key,
    required this.attendance,
    required this.allEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participant Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${attendance.totalParticipants} ${attendance.totalParticipants == 1 ? 'participant' : 'participants'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Participant list with history
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: attendance.participants.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final participant = attendance.participants[index];
                  final participantEvents = _getParticipantEvents(participant);
                  return _buildParticipantSection(context, participant, participantEvents);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SessionParticipantEvent> _getParticipantEvents(SessionParticipant participant) {
    return allEvents.where((event) {
      // Match by userId, participantId, or name
      final matchesUserId = participant.participantId == event.userId;
      final matchesParticipantId = participant.participantId == event.participantId;
      final matchesName = participant.participantName == event.participantName;

      return matchesUserId || matchesParticipantId || matchesName;
    }).toList();
  }

  Widget _buildParticipantSection(
    BuildContext context,
    SessionParticipant participant,
    List<SessionParticipantEvent> events,
  ) {
    final timeFormat = DateFormat('hh:mm a');

    Color statusColor;
    IconData statusIcon;

    switch (participant.status) {
      case AttendanceStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case AttendanceStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case AttendanceStatus.noShow:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.notStarted:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
        break;
    }

    // Sort events by time (newest first)
    events.sort((a, b) => b.eventTime.compareTo(a.eventTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Participant header
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withOpacity(0.2),
              child: participant.participantAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        participant.participantAvatar!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: statusColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: statusColor,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.participantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    participant.participantType == 'MENTOR' ? 'Mentor' : 'Job Seeker',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    participant.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Summary stats
        if (participant.joinedAt != null || participant.durationMinutes != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (participant.joinedAt != null)
                  Row(
                    children: [
                      Icon(Icons.login, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Joined: ${timeFormat.format(participant.joinedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (participant.joinedAt != null && participant.leftAt != null)
                  const SizedBox(height: 6),
                if (participant.leftAt != null)
                  Row(
                    children: [
                      Icon(Icons.logout, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Left: ${timeFormat.format(participant.leftAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (participant.durationMinutes != null) ...[
                  if (participant.joinedAt != null || participant.leftAt != null)
                    const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: ${participant.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Event history
        if (events.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Event History',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          ...events.map((event) => _buildEventItem(context, event)),
        ],
      ],
    );
  }

  Widget _buildEventItem(BuildContext context, SessionParticipantEvent event) {
    final timeFormat = DateFormat('hh:mm:ss a');

    Color eventColor;
    IconData eventIcon;
    String eventLabel;

    switch (event.eventType) {
      case ParticipantEventType.joined:
        eventColor = Colors.green;
        eventIcon = Icons.login;
        eventLabel = 'Joined';
        break;
      case ParticipantEventType.left:
        eventColor = Colors.orange;
        eventIcon = Icons.logout;
        eventLabel = 'Left';
        break;
      case ParticipantEventType.joinedLobby:
        eventColor = Colors.blue;
        eventIcon = Icons.meeting_room;
        eventLabel = 'Joined Lobby';
        break;
      case ParticipantEventType.leftLobby:
        eventColor = Colors.grey;
        eventIcon = Icons.exit_to_app;
        eventLabel = 'Left Lobby';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              eventIcon,
              size: 16,
              color: eventColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormat.format(event.eventTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (event.disconnectReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${event.disconnectReason}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
