import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/session_participant_event.dart';

class SessionActivityLogWidget extends StatelessWidget {
  final List<SessionParticipantEvent> events;

  const SessionActivityLogWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No activity log available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Activity Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${events.length} ${events.length == 1 ? 'event' : 'events'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...events.map((event) => _buildActivityItem(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, SessionParticipantEvent event) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    Color eventColor;
    IconData eventIcon;

    switch (event.eventType) {
      case ParticipantEventType.joined:
        eventColor = Colors.green;
        eventIcon = Icons.login;
        break;
      case ParticipantEventType.left:
        eventColor = Colors.orange;
        eventIcon = Icons.logout;
        break;
      case ParticipantEventType.joinedLobby:
        eventColor = Colors.blue;
        eventIcon = Icons.meeting_room;
        break;
      case ParticipantEventType.leftLobby:
        eventColor = Colors.grey;
        eventIcon = Icons.exit_to_app;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: eventColor, width: 2),
                ),
                child: Icon(
                  eventIcon,
                  color: eventColor,
                  size: 20,
                ),
              ),
              if (events.last != event)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.eventType.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.eventType.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.participantName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  event.participantType == 'MENTOR' ? 'Mentor' : 'Job Seeker',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(event.eventTime)} at ${timeFormat.format(event.eventTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                if (event.disconnectReason != null && event.disconnectReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Disconnect reason: ${event.disconnectReason}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (event.participantEmail != null && event.participantEmail!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.participantEmail!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
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
