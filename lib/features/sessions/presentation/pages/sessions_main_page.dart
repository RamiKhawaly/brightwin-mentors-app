import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/sessions_repository.dart';
import '../../domain/entities/session.dart';

class SessionsMainPage extends StatefulWidget {
  final int initialTabIndex;

  const SessionsMainPage({super.key, this.initialTabIndex = 0});

  @override
  State<SessionsMainPage> createState() => _SessionsMainPageState();
}

class _SessionsMainPageState extends State<SessionsMainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SessionsRepository _repository;

  // Requests tab
  List<Session> _pendingRequests = [];
  bool _isPendingLoading = true;

  // Upcoming tab
  List<Session> _upcomingSessions = [];
  bool _isUpcomingLoading = true;

  // Past tab
  List<Session> _pastSessions = [];
  bool _isPastLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = SessionsRepository(dioClient);

    _loadAllData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Reload data when tab changes
        _loadTabData(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadPendingRequests(),
      _loadUpcomingSessions(),
      _loadPastSessions(),
    ]);
  }

  Future<void> _loadTabData(int index) async {
    switch (index) {
      case 0:
        await _loadPendingRequests();
        break;
      case 1:
        await _loadUpcomingSessions();
        break;
      case 2:
        await _loadPastSessions();
        break;
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isPendingLoading = true;
    });

    try {
      final sessions = await _repository.getPendingRequests();
      setState(() {
        _pendingRequests = sessions;
        _isPendingLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPendingLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingSessions() async {
    setState(() {
      _isUpcomingLoading = true;
    });

    try {
      final sessions = await _repository.getUpcomingSessions();
      setState(() {
        _upcomingSessions = sessions;
        _isUpcomingLoading = false;
      });
    } catch (e) {
      setState(() {
        _isUpcomingLoading = false;
      });
    }
  }

  Future<void> _loadPastSessions() async {
    setState(() {
      _isPastLoading = true;
    });

    try {
      final sessions = await _repository.getMySessions(status: 'COMPLETED');
      setState(() {
        _pastSessions = sessions;
        _isPastLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPastLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _pendingRequests.isNotEmpty,
                label: Text('${_pendingRequests.length}'),
                child: const Icon(Icons.inbox),
              ),
              text: 'Requests',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _upcomingSessions.isNotEmpty,
                label: Text('${_upcomingSessions.length}'),
                child: const Icon(Icons.upcoming),
              ),
              text: 'Upcoming',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'Past',
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildUpcomingTab(),
            _buildPastTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isPendingLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Pending Requests',
        subtitle: 'New session requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          return _buildSessionCard(_pendingRequests[index], showStatus: false);
        },
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isUpcomingLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_outlined,
        title: 'No Upcoming Sessions',
        subtitle: 'Your scheduled sessions will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpcomingSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingSessions.length,
        itemBuilder: (context, index) {
          return _buildSessionCard(_upcomingSessions[index]);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_isPastLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_outlined,
        title: 'No Past Sessions',
        subtitle: 'Completed sessions will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPastSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pastSessions.length,
        itemBuilder: (context, index) {
          return _buildSessionCard(_pastSessions[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, {bool showStatus = true}) {
    final dateFormat = DateFormat('MMM dd, yyyy');
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
      child: InkWell(
        onTap: () async {
          await context.push('/sessions/${session.id}');
          // Refresh data when returning from session details
          _loadTabData(_tabController.index);
        },
        borderRadius: BorderRadius.circular(12),
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
                      if (showStatus) ...[
                        const SizedBox(height: 4),
                        _buildStatusChip(session.status),
                      ],
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
}
