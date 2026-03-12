import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/data/repositories/sessions_repository.dart';
import '../../../sessions/presentation/pages/sessions_main_page.dart';
import '../../../jobs/presentation/pages/my_jobs_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/data/models/user_profile_response_model.dart';
import '../../../applications/presentation/pages/applications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _sessionsTabIndex = 0; // Track which sessions tab to show
  late final DashboardRepositoryImpl _repository;
  late final SessionsRepository _sessionsRepository;
  late final ProfileRepositoryImpl _profileRepository;
  late final DioClient _dioClient;
  DashboardStats? _stats;
  UserProfileResponseModel? _userProfile;
  bool _isLoading = true;
  List<Session> _upcomingSessions = [];
  List<Session> _pendingRequests = [];
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(const FlutterSecureStorage());
    _repository = DashboardRepositoryImpl(_dioClient);
    _sessionsRepository = SessionsRepository(_dioClient);
    _profileRepository = ProfileRepositoryImpl(_dioClient);
    _loadDashboardData();
    _loadUserProfile();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version}';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('👤 Loading user profile for drawer...');
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
        print('✅ User profile loaded: ${profile.firstName} ${profile.lastName}');
      }
    } catch (e) {
      print('❌ Error loading user profile for drawer: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 Loading dashboard data...');

      // Load dashboard stats
      final stats = await _repository.getDashboardStats();
      print('✅ Dashboard stats loaded');

      // Load upcoming sessions and pending requests in parallel
      final results = await Future.wait([
        _loadUpcomingSessions(),
        _loadPendingRequests(),
      ]);

      final sessions = results[0] as List<Session>;
      final pendingRequests = results[1] as List<Session>;

      if (mounted) {
        setState(() {
          _stats = stats;
          _upcomingSessions = sessions;
          _pendingRequests = pendingRequests;
          _isLoading = false;
        });
        print('✅ Dashboard data loaded successfully');
        print('   - ${sessions.length} upcoming sessions');
        print('   - ${pendingRequests.length} pending requests');
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _stats = DashboardStats.empty();
          _upcomingSessions = [];
          _pendingRequests = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Session>> _loadUpcomingSessions() async {
    try {
      print('📡 Fetching upcoming sessions for dashboard');
      final response = await _dioClient.dio.get('/api/mentorship/sessions/mentor/my');

      if (response.data == null) {
        return [];
      }

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['sessions'] ?? response.data['data'] ?? []);

      if (data.isEmpty) {
        print('No sessions data received');
        return [];
      }

      // Parse all sessions
      final allSessions = data.map((json) => _sessionFromJson(json)).toList();

      // Filter for confirmed sessions with scheduled dates
      final upcomingSessions = allSessions.where((session) {
        return session.status == SessionStatus.confirmed &&
               session.scheduledAt != null &&
               session.scheduledAt!.isAfter(DateTime.now());
      }).toList();

      // Sort by scheduled time
      upcomingSessions.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

      print('✅ Found ${upcomingSessions.length} upcoming sessions');
      return upcomingSessions;
    } catch (e) {
      print('❌ Error loading upcoming sessions: $e');
      return [];
    }
  }

  Future<List<Session>> _loadPendingRequests() async {
    try {
      print('📡 Fetching pending session requests for dashboard');
      final pendingRequests = await _sessionsRepository.getPendingRequests();

      // Sort by creation date (newest first)
      pendingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Found ${pendingRequests.length} pending session requests');
      return pendingRequests;
    } catch (e) {
      print('❌ Error loading pending requests: $e');
      return [];
    }
  }

  Session _sessionFromJson(Map<String, dynamic> json) {
    // Parse scheduled date from various possible field names
    DateTime? scheduledDate;
    final dateStr = json['scheduledDate'] ?? json['scheduledAt'] ?? json['date'];
    if (dateStr != null) {
      try {
        scheduledDate = DateTime.parse(dateStr);
      } catch (e) {
        print('⚠️ Error parsing scheduled date: $e');
      }
    }

    return Session(
      id: json['id'].toString(),
      type: _parseSessionType(json['serviceType'] ?? json['type']),
      status: _parseSessionStatus(json['status']),
      jobSeekerId: json['jobSeekerId']?.toString() ?? json['studentId']?.toString() ?? '',
      jobSeekerName: json['jobSeekerName'] ?? json['studentName'] ?? 'Unknown',
      jobSeekerAvatar: json['jobSeekerAvatar'],
      scheduledAt: scheduledDate,
      durationMinutes: json['durationMinutes'] ?? 60,
      notes: json['notes'] ?? json['requestMessage'],
      topic: json['topic'],
      proposedTimeSlots: null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      feedbackId: json['feedbackId']?.toString(),
      jobId: json['jobId'] as int? ?? json['jobPostingId'] as int?,
      meetingLink: json['meetingLink'],
    );
  }

  SessionType _parseSessionType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MOCK_INTERVIEW':
      case 'INTERVIEW_SIMULATION':
      case 'SIMULATION':
        return SessionType.simulation;
      case 'PHONE_CALL':
      case 'CALL':
        return SessionType.call;
      case 'CHAT_TIPS':
      case 'CHAT':
        return SessionType.chat;
      default:
        return SessionType.chat;
    }
  }

  SessionStatus _parseSessionStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return SessionStatus.pending;
      case 'AWAITING_SEEKER_RESPONSE':
        return SessionStatus.awaitingSeekerResponse;
      case 'NEGOTIATING':
        return SessionStatus.negotiating;
      case 'APPROVED':
      case 'CONFIRMED':
        return SessionStatus.confirmed;
      case 'CANCELLED_BY_MENTOR':
        return SessionStatus.cancelledByMentor;
      case 'CANCELLED_BY_SEEKER':
        return SessionStatus.cancelledBySeeker;
      case 'CANCELLED_NO_AGREEMENT':
        return SessionStatus.cancelledNoAgreement;
      case 'RESCHEDULED':
        return SessionStatus.rescheduled;
      case 'COMPLETED':
        return SessionStatus.completed;
      case 'NO_SHOW_MENTOR':
        return SessionStatus.noShowMentor;
      case 'NO_SHOW_SEEKER':
        return SessionStatus.noShowSeeker;
      default:
        return SessionStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            // Reset sessions tab to Requests (0) when navigating via bottom nav
            if (index == 2) {
              _sessionsTabIndex = 0;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Applications',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildDashboard();
        break;
      case 1:
        content = const MyJobsPage();
        break;
      case 2:
        content = SessionsMainPage(initialTabIndex: _sessionsTabIndex);
        break;
      case 3:
        content = const ApplicationsPage();
        break;
      default:
        content = _buildDashboard();
    }

    return SafeArea(
      bottom: true,
      child: content,
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push(AppRoutes.notifications);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading or Stats Cards
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                      // Profile Completion Banner
                    if (_userProfile != null) _buildProfileCompletionBanner(),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Active Jobs',
                            value: '${_stats?.activeJobs ?? 0}',
                            icon: Icons.work_outline,
                            color: Colors.blue,
                            onTap: () {
                              setState(() {
                                _selectedIndex = 1; // Navigate to Jobs tab
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Sessions',
                            value: '${_stats?.sessions ?? 0}',
                            icon: Icons.people,
                            color: Colors.purple,
                            onTap: () {
                              setState(() {
                                _selectedIndex = 2; // Navigate to Sessions tab
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Session Requests - show if there are pending requests
                    if (_pendingRequests.isNotEmpty) ...[
                      _buildSessionRequestsCard(),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Highlighted Post a Job Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showJobPostingOptions(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_business,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Post a Job',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Share internal positions and earn referral bonuses',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upcoming Sessions
                  Text(
                    'Upcoming Sessions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingSessionsSummary(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isProfileEmpty() {
    if (_userProfile == null) return true;
    final hasLinkedIn = _userProfile!.linkedInUrl != null && _userProfile!.linkedInUrl!.isNotEmpty;
    final hasCompany = (_userProfile!.companyHistory != null && _userProfile!.companyHistory!.isNotEmpty) ||
        (_userProfile!.currentCompany != null && _userProfile!.currentCompany!.name.isNotEmpty);
    final hasExperience = _userProfile!.experiences != null && _userProfile!.experiences!.isNotEmpty;
    final hasEducation = _userProfile!.education != null && _userProfile!.education!.isNotEmpty;
    final hasSkills = _userProfile!.skills != null && _userProfile!.skills!.isNotEmpty;
    final hasBio = _userProfile!.bio != null && _userProfile!.bio!.isNotEmpty;
    final hasJobTitle = _userProfile!.currentJobTitle != null && _userProfile!.currentJobTitle!.isNotEmpty;

    return !hasLinkedIn && !hasCompany && !hasExperience && !hasEducation && !hasSkills && !hasBio && !hasJobTitle;
  }

  Widget _buildProfileCompletionBanner() {
    if (!_isProfileEmpty()) return const SizedBox.shrink();

    const Color bannerColor = Color(0xFFFFFDE7); // light yellow
    const Color accentColor = Color(0xFFF9A825); // amber

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            color: accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add your companies, LinkedIn, CV and more to attract job seekers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await context.push(AppRoutes.profile);
              _loadUserProfile();
            },
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionRequestsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade600,
            Colors.orange.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _sessionsTabIndex = 0; // Set to Requests tab (index 0)
              _selectedIndex = 2; // Navigate to Sessions tab
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Session Requests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingRequests.length}',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have pending session requests that need your attention',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Show preview of first few requests
                ..._pendingRequests.take(2).map((session) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.jobSeekerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session.type.displayName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSessionStatusBadge(session.status),
                      ],
                    ),
                  );
                }).toList(),
                if (_pendingRequests.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '+ ${_pendingRequests.length - 2} more',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatusBadge(SessionStatus status) {
    String text;
    switch (status) {
      case SessionStatus.pending:
        text = 'New';
        break;
      case SessionStatus.awaitingSeekerResponse:
        text = 'Waiting';
        break;
      case SessionStatus.negotiating:
        text = 'Negotiating';
        break;
      default:
        text = status.toString().split('.').last;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsSummary() {
    if (_upcomingSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No upcoming sessions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _upcomingSessions.take(3).map((session) {
        final sessionColor = _getSessionColor(session.type);
        final timeText = session.scheduledAt != null
            ? _formatSessionTime(session.scheduledAt!)
            : 'Time TBD';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  _sessionsTabIndex = 1; // Set to Upcoming tab (index 1)
                  _selectedIndex = 2; // Navigate to Sessions tab
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sessionColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Session info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.type.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  session.jobSeekerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(height: 4),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.simulation:
        return Colors.blue;
      case SessionType.call:
        return Colors.green;
      case SessionType.chat:
        return Colors.purple;
    }
  }

  String _formatSessionTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (sessionDate == today) {
      return 'Today, $timeStr';
    } else if (sessionDate == tomorrow) {
      return 'Tomorrow, $timeStr';
    } else {
      final daysUntil = sessionDate.difference(today).inDays;
      if (daysUntil < 7) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${weekdays[dateTime.weekday - 1]}, $timeStr';
      } else {
        return '${dateTime.day}/${dateTime.month}, $timeStr';
      }
    }
  }

  void _showJobPostingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post a Job',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add the job',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text('Import from URL'),
                subtitle: const Text('Paste a job link and AI will extract details'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push('${AppRoutes.jobPosting}/import');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit),
                ),
                title: const Text('Create Manually'),
                subtitle: const Text('Fill in all job details yourself'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.jobPosting);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: _userProfile?.imageUrl != null && _userProfile!.imageUrl!.isNotEmpty
                      ? NetworkImage(_userProfile!.imageUrl!)
                      : null,
                  child: _userProfile?.imageUrl == null || _userProfile!.imageUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                // User Name
                Text(
                  _userProfile != null
                      ? '${_userProfile!.firstName} ${_userProfile!.lastName}'
                      : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // User Email
                Text(
                  _userProfile?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.push(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.notifications);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Suggestions & Support'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.suggestions);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Mentor Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.mentorSettings);
            },
          ),
          const Divider(),
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                // Clear secure storage and navigate to login
                final storage = const FlutterSecureStorage();
                await storage.deleteAll();
                if (context.mounted) {
                  context.go(AppRoutes.signIn);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
