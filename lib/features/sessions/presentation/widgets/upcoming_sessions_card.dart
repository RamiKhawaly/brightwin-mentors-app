import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/session.dart';

class UpcomingSessionsCard extends StatelessWidget {
  final List<Session> upcomingSessions;
  final VoidCallback onTap;

  const UpcomingSessionsCard({
    super.key,
    required this.upcomingSessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pendingSessions = upcomingSessions
        .where((session) => session.status == SessionStatus.pending)
        .length;

    return Card(
      elevation: 2,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Sessions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${upcomingSessions.length} scheduled',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (pendingSessions > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$pendingSessions pending',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              if (upcomingSessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildNextSession(context, upcomingSessions.first),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextSession(BuildContext context, Session session) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Row(
      children: [
        Text(
          session.type.icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next: ${session.type.displayName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'with ${session.jobSeekerName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                session.scheduledAt != null
                    ? dateFormat.format(session.scheduledAt!)
                    : 'Time TBD',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
