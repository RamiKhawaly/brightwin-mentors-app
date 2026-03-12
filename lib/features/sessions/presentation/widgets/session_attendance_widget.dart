import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/session_attendance.dart';

class SessionAttendanceWidget extends StatelessWidget {
  final SessionAttendance attendance;
  final VoidCallback? onTap;

  const SessionAttendanceWidget({
    super.key,
    required this.attendance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (onTap != null) ...[
                    Icon(
                      Icons.touch_app,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap for details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Summary row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total',
                      attendance.totalParticipants.toString(),
                      Icons.group,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Present',
                      attendance.presentCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Absent',
                      attendance.absentCount.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              if (attendance.participants.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...attendance.participants.map((participant) => _buildParticipantTile(context, participant)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(BuildContext context, SessionParticipant participant) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: participant.participantAvatar != null
              ? ClipOval(
                  child: Image.network(
                    participant.participantAvatar!,
                    width: 40,
                    height: 40,
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
        title: Text(
          participant.participantName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              participant.participantType == 'MENTOR' ? 'Mentor' : 'Job Seeker',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (participant.joinedAt != null)
              Text(
                'Joined: ${timeFormat.format(participant.joinedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
              ),
            if (participant.leftAt != null)
              Text(
                'Left: ${timeFormat.format(participant.leftAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
              ),
            if (participant.durationMinutes != null)
              Text(
                'Duration: ${participant.durationMinutes} minutes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                participant.status.displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
