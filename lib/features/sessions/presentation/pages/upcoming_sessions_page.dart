import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/session.dart';

class UpcomingSessionsPage extends StatefulWidget {
  const UpcomingSessionsPage({super.key});

  @override
  State<UpcomingSessionsPage> createState() => _UpcomingSessionsPageState();
}

class _UpcomingSessionsPageState extends State<UpcomingSessionsPage> {
  // TODO: Replace with actual data from repository
  List<Session> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data
    setState(() {
      _sessions = [
        Session(
          id: '1',
          type: SessionType.simulation,
          status: SessionStatus.pending,
          jobSeekerId: 'user-1',
          jobSeekerName: 'Sarah Cohen',
          scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
          durationMinutes: 60,
          topic: 'Technical Interview - React & Node.js',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Session(
          id: '2',
          type: SessionType.call,
          status: SessionStatus.confirmed,
          jobSeekerId: 'user-2',
          jobSeekerName: 'David Levy',
          scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 5)),
          durationMinutes: 30,
          topic: 'Career Guidance Discussion',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Session(
          id: '3',
          type: SessionType.chat,
          status: SessionStatus.pending,
          jobSeekerId: 'user-3',
          jobSeekerName: 'Rachel Green',
          scheduledAt: DateTime.now().add(const Duration(days: 3)),
          durationMinutes: 45,
          topic: 'Resume Review',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Sessions'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(context, _sessions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Upcoming Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your scheduled sessions will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Session session) {
    final dateFormat = DateFormat('EEEE, MMM dd');
    final timeFormat = DateFormat('hh:mm a');

    // Get icon based on session type
    IconData sessionIcon;
    switch (session.type) {
      case SessionType.call:
        sessionIcon = Icons.phone;
        break;
      case SessionType.simulation:
        sessionIcon = Icons.psychology;
        break;
      case SessionType.chat:
        sessionIcon = Icons.chat_bubble_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sessionIcon,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.type.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested by:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.jobSeekerName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (session.scheduledAt == null)
                      Icon(
                        Icons.schedule,
                        color: Colors.orange[400],
                        size: 20,
                      ),
                    const SizedBox(height: 4),
                    _buildStatusChip(session.status),
                  ],
                ),
              ],
            ),
            if (session.scheduledAt != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(session.scheduledAt!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(session.scheduledAt!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${session.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (session.topic != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.subject, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.topic!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (session.status == SessionStatus.pending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPostponeDialog(context, session),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('Postpone'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSession(context, session),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (session.status == SessionStatus.confirmed) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinSession(context, session),
                      icon: const Icon(Icons.videocam, size: 18),
                      label: const Text('Join Session'),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showCancelDialog(context, session),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SessionStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case SessionStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case SessionStatus.awaitingSeekerResponse:
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        break;
      case SessionStatus.negotiating:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case SessionStatus.confirmed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case SessionStatus.cancelledByMentor:
      case SessionStatus.cancelledBySeeker:
      case SessionStatus.cancelledNoAgreement:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case SessionStatus.rescheduled:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[900]!;
        break;
      case SessionStatus.completed:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[900]!;
        break;
      case SessionStatus.noShowMentor:
      case SessionStatus.noShowSeeker:
        backgroundColor = Colors.deepOrange[100]!;
        textColor = Colors.deepOrange[900]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _approveSession(BuildContext context, Session session) {
    // TODO: Implement approve session API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session with ${session.jobSeekerName} approved'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo
          },
        ),
      ),
    );

    setState(() {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = Session(
          id: session.id,
          type: session.type,
          status: SessionStatus.confirmed,
          jobSeekerId: session.jobSeekerId,
          jobSeekerName: session.jobSeekerName,
          jobSeekerAvatar: session.jobSeekerAvatar,
          scheduledAt: session.scheduledAt,
          durationMinutes: session.durationMinutes,
          notes: session.notes,
          topic: session.topic,
          createdAt: session.createdAt,
        );
      }
    });
  }

  void _showPostponeDialog(BuildContext context, Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Postpone Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Postpone session with ${session.jobSeekerName}?'),
            const SizedBox(height: 16),
            const Text(
              'The job seeker will be notified and asked to reschedule.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _postponeSession(context, session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Postpone'),
          ),
        ],
      ),
    );
  }

  void _postponeSession(BuildContext context, Session session) {
    // TODO: Implement postpone session API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session with ${session.jobSeekerName} postponed'),
        backgroundColor: Colors.orange,
      ),
    );

    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
    });
  }

  void _showCancelDialog(BuildContext context, Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel session with ${session.jobSeekerName}?'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. The job seeker will be notified.',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSession(context, session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  void _cancelSession(BuildContext context, Session session) {
    // TODO: Implement cancel session API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session with ${session.jobSeekerName} cancelled'),
        backgroundColor: Colors.red,
      ),
    );

    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
    });
  }

  void _joinSession(BuildContext context, Session session) {
    // TODO: Implement join session functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Joining session...'),
      ),
    );
  }
}
