import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/repositories/sessions_repository.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_attendance.dart';
import '../../domain/entities/session_participant_event.dart';
import '../../data/models/propose_slots_request.dart';
import '../../../jobs/data/repositories/job_repository_impl.dart';
import '../../../jobs/data/models/job_response_model.dart';
import '../../../feedback/presentation/pages/rate_candidate_page.dart';
import '../widgets/session_attendance_widget.dart';
import '../widgets/session_activity_log_widget.dart';
import '../widgets/participant_history_dialog.dart';
import 'candidate_profile_viewer_page.dart';

class SessionDetailsPage extends StatefulWidget {
  final String sessionId;

  const SessionDetailsPage({super.key, required this.sessionId});

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  late final SessionsRepository _repository;
  late final JobRepositoryImpl _jobRepository;
  Session? _session;
  SessionAttendance? _attendance;
  List<SessionParticipantEvent>? _activityLog;
  bool _isLoading = true;
  bool _isLoadingAttendance = false;
  bool _isLoadingActivityLog = false;
  String? _errorMessage;
  String? _attendanceError;
  String? _activityLogError;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = SessionsRepository(dioClient);
    _jobRepository = JobRepositoryImpl(dioClient);
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _repository.getSessionDetails(widget.sessionId);
      setState(() {
        _session = session;
        _isLoading = false;
      });

      // Load participant events for confirmed and completed sessions
      if (session.status == SessionStatus.confirmed || session.status == SessionStatus.completed) {
        _loadParticipantEvents();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load session details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadParticipantEvents() async {
    setState(() {
      _isLoadingAttendance = true;
      _isLoadingActivityLog = true;
      _attendanceError = null;
      _activityLogError = null;
    });

    try {
      final events = await _repository.getSessionParticipantEvents(widget.sessionId);

      setState(() {
        _activityLog = events;
        _isLoadingActivityLog = false;

        // Derive attendance from events for confirmed sessions
        if (_session?.status == SessionStatus.confirmed) {
          _attendance = _repository.deriveAttendance(widget.sessionId, events);
        }
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() {
        _attendanceError = 'Failed to load participant data: ${e.toString()}';
        _activityLogError = _attendanceError;
        _isLoadingAttendance = false;
        _isLoadingActivityLog = false;
      });
    }
  }

  void _showParticipantHistoryDialog() {
    if (_attendance == null || _activityLog == null) return;

    showDialog(
      context: context,
      builder: (context) => ParticipantHistoryDialog(
        attendance: _attendance!,
        allEvents: _activityLog!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _session == null
                    ? _buildEmptyState()
                    : _buildSessionDetails(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSessionDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Session Not Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetails() {
    final session = _session!;
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Session Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.type.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(session.status),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.person,
                    'Job Seeker',
                    session.jobSeekerName,
                  ),
                  const SizedBox(height: 12),
                  // View Candidate Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _viewCandidateProfile(),
                      icon: const Icon(Icons.account_circle),
                      label: const Text('View Candidate Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.timer,
                    'Duration',
                    '${session.durationMinutes} minutes',
                  ),
                  if (session.topic != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.subject,
                      'Topic',
                      session.topic!,
                    ),
                  ],
                  if (session.jobId != null) ...[
                    const SizedBox(height: 12),
                    _buildJobLinkRow(),
                  ],
                  if (session.scheduledAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Scheduled',
                      '${dateFormat.format(session.scheduledAt!)} at ${timeFormat.format(session.scheduledAt!)}',
                    ),
                  ],
                  if (session.meetingLink != null && session.meetingLink!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMeetingLinkRow(session.meetingLink!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Proposed Time Slots
          if (session.proposedTimeSlots != null &&
              session.proposedTimeSlots!.isNotEmpty) ...[
            Text(
              'Proposed Time Slots',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...session.proposedTimeSlots!.map((slot) => _buildTimeSlotCard(slot)),
            const SizedBox(height: 16),
          ],

          // Attendance (for confirmed sessions)
          if (session.status == SessionStatus.confirmed) ...[
            if (_isLoadingAttendance)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_attendanceError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _attendanceError!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadParticipantEvents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_attendance != null)
              SessionAttendanceWidget(
                attendance: _attendance!,
                onTap: _activityLog != null ? () => _showParticipantHistoryDialog() : null,
              ),
            const SizedBox(height: 16),
          ],

          // Activity Log (for completed sessions)
          if (session.status == SessionStatus.completed) ...[
            if (_isLoadingActivityLog)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_activityLogError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _activityLogError!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadParticipantEvents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_activityLog != null)
              SessionActivityLogWidget(events: _activityLog!),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          _buildActionButtons(session),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobLinkRow() {
    return InkWell(
      onTap: () => _showJobDetailsDialog(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.work_outline, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Job',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View job posting',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingLinkRow(String meetingLink) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.videocam, size: 20, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting Link',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  meetingLink,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(meetingLink),
            icon: Icon(Icons.copy, size: 20, color: Colors.green[700]),
            tooltip: 'Copy link',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final dateFormat = DateFormat('EEEE, MMM dd');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: slot.isSelected ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              slot.isSelected ? Icons.check_circle : Icons.schedule,
              color: slot.isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(slot.startTime),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (slot.proposedBy != null)
                    Text(
                      'Proposed by ${slot.proposedBy}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Session session) {
    if (session.status == SessionStatus.pending) {
      return Column(
        children: [
          CustomButton(
            text: 'Propose Time Slots',
            onPressed: () => _showProposeTimeSlotsDialog(),
            icon: Icons.schedule,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Decline Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (session.status == SessionStatus.negotiating) {
      return Column(
        children: [
          CustomButton(
            text: 'Propose New Time Slots',
            onPressed: () => _showProposeTimeSlotsDialog(),
            icon: Icons.schedule,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (session.status == SessionStatus.confirmed) {
      final hasMeetingLink = session.meetingLink != null && session.meetingLink!.isNotEmpty;

      return Column(
        children: [
          if (hasMeetingLink)
            CustomButton(
              text: 'Join Session',
              onPressed: () => _joinSession(),
              icon: Icons.videocam,
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.videocam_off),
                label: const Text('No Meeting Link Available'),
              ),
            ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Complete Session',
            onPressed: () => _completeSession(),
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRescheduleDialog(),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (session.status == SessionStatus.completed) {
      return CustomButton(
        text: 'View Feedback',
        onPressed: () {},
        icon: Icons.feedback_outlined,
        isOutlined: true,
      );
    }

    return const SizedBox.shrink();
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

  void _showProposeTimeSlotsDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProposeTimeSlotsDialog(
        sessionId: widget.sessionId,
        repository: _repository,
        onProposed: () {
          _loadSessionDetails();
        },
        sessionDuration: _session?.durationMinutes ?? 60,
      ),
    );
  }

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => _RescheduleDialog(
        sessionId: widget.sessionId,
        repository: _repository,
        onRescheduled: () {
          _loadSessionDetails();
        },
        sessionDuration: _session?.durationMinutes ?? 60,
      ),
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this session?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Please explain why you need to cancel',
              ),
              maxLines: 3,
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
              _cancelSession(reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSession(String reason) async {
    try {
      await _repository.cancelSession(widget.sessionId, reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinSession() async {
    final session = _session;
    if (session == null || session.meetingLink == null || session.meetingLink!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No meeting link available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(session.meetingLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: ${session.meetingLink}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting link copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _completeSession() async {
    final session = _session;
    if (session == null) return;

    // Parse session ID to int
    int sessionIdInt;
    try {
      sessionIdInt = int.parse(session.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid session ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse job seeker ID to int
    int jobSeekerIdInt;
    try {
      jobSeekerIdInt = int.parse(session.jobSeekerId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid job seeker ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to candidate rating page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateCandidatePage(
          sessionId: sessionIdInt,
          jobSeekerId: jobSeekerIdInt,
          jobSeekerName: session.jobSeekerName,
        ),
      ),
    );

    // If rating was submitted successfully, reload session details
    if (result == true) {
      _loadSessionDetails();
    }
  }

  Future<void> _viewCandidateProfile() async {
    final session = _session;
    if (session == null) return;

    // Parse job seeker ID to int
    int jobSeekerIdInt;
    try {
      jobSeekerIdInt = int.parse(session.jobSeekerId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid job seeker ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to candidate profile viewer page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateProfileViewerPage(
          candidateId: jobSeekerIdInt,
        ),
      ),
    );
  }

  void _showJobDetailsDialog() async {
    final session = _session!;

    if (session.jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No job associated with this session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch job details
      final job = await _jobRepository.getJobById(session.jobId!);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show job details dialog
      if (!mounted) return;
      setState(() {
        _isDescriptionExpanded = false;
      });
      showDialog(
        context: context,
        builder: (context) => _buildJobDetailsDialog(job),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load job details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildJobDetailsDialog(JobResponseModel job) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Related Job',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                    const SizedBox(height: 16),

                    // Job Title
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Description (expandable)
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: _isDescriptionExpanded ? null : 3,
                            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _isDescriptionExpanded ? 'Show less' : 'Read more',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                _isDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                if (job.techStack != null && job.techStack!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // Required Skills
                  Text(
                    'Required Skills',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.techStack!.map((skill) => _buildSkillChip(skill)).toList(),
                  ),
                ],

                if (job.referralBonus != null && job.referralBonus! > 0) ...[
                  const SizedBox(height: 20),
                  // Compensation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Referral Bonus',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${job.salaryCurrency ?? '₪'}${NumberFormat('#,###').format(job.referralBonus)}',
                                style: TextStyle(
                                  color: Colors.green[900],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (job.salaryMin != null || job.salaryMax != null) ...[
                  const SizedBox(height: 12),
                  // Salary Range
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salary Range',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.salaryMin != null && job.salaryMax != null
                                    ? '${job.salaryCurrency ?? '₪'}${NumberFormat('#,###').format(job.salaryMin)} - ${job.salaryCurrency ?? '₪'}${NumberFormat('#,###').format(job.salaryMax)}'
                                    : job.salaryMin != null
                                        ? 'From ${job.salaryCurrency ?? '₪'}${NumberFormat('#,###').format(job.salaryMin)}'
                                        : 'Up to ${job.salaryCurrency ?? '₪'}${NumberFormat('#,###').format(job.salaryMax)}',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProposeTimeSlotsDialog extends StatefulWidget {
  final String sessionId;
  final SessionsRepository repository;
  final VoidCallback onProposed;
  final int sessionDuration;

  const _ProposeTimeSlotsDialog({
    required this.sessionId,
    required this.repository,
    required this.onProposed,
    required this.sessionDuration,
  });

  @override
  State<_ProposeTimeSlotsDialog> createState() => _ProposeTimeSlotsDialogState();
}

class _ProposeTimeSlotsDialogState extends State<_ProposeTimeSlotsDialog> {
  final List<DateTime?> _startTimes = [null, null, null];
  bool _isSubmitting = false;

  Future<void> _selectDateTime(int index) async {
    // Select date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: index + 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (selectedDate == null || !mounted) return;

    // Select time
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10 + (index * 2), minute: 0),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _startTimes[index] = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _submitProposal() async {
    // Validate at least one slot is filled
    if (_startTimes.every((time) => time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timeSlots = _startTimes
          .where((startTime) => startTime != null)
          .map((startTime) {
        return TimeSlotProposal(
          startTime: startTime!,
          endTime: startTime.add(Duration(minutes: widget.sessionDuration)),
        );
      }).toList();

      final request = ProposeSlotsRequest(timeSlots: timeSlots);
      await widget.repository.proposeTimeSlots(widget.sessionId, request);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onProposed();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slots proposed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to propose time slots: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Propose Time Slots',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
              const SizedBox(height: 8),
              Text(
                'Select 1-3 time slots for the candidate to choose from',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Time slot 1
              _buildTimeSlotCard(0, dateFormat, timeFormat),
              const SizedBox(height: 16),

              // Time slot 2
              _buildTimeSlotCard(1, dateFormat, timeFormat),
              const SizedBox(height: 16),

              // Time slot 3
              _buildTimeSlotCard(2, dateFormat, timeFormat),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProposal,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Propose'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(int index, DateFormat dateFormat, DateFormat timeFormat) {
    final startTime = _startTimes[index];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _selectDateTime(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: startTime != null ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  startTime != null ? Icons.check_circle : Icons.schedule,
                  color: startTime != null ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Slot ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startTime != null
                          ? '${dateFormat.format(startTime)}\n${timeFormat.format(startTime)} - ${timeFormat.format(startTime.add(Duration(minutes: widget.sessionDuration)))}'
                          : 'Tap to select date and time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: startTime != null ? Colors.black87 : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RescheduleDialog extends StatefulWidget {
  final String sessionId;
  final SessionsRepository repository;
  final VoidCallback onRescheduled;
  final int sessionDuration;

  const _RescheduleDialog({
    required this.sessionId,
    required this.repository,
    required this.onRescheduled,
    required this.sessionDuration,
  });

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  final List<DateTime?> _startTimes = [null, null, null];
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(int index) async {
    // Select date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: index + 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (selectedDate == null || !mounted) return;

    // Select time
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10 + (index * 2), minute: 0),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _startTimes[index] = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _submitReschedule() async {
    // Validate at least one slot is filled
    if (_startTimes.every((time) => time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timeSlots = _startTimes
          .where((startTime) => startTime != null)
          .map((startTime) {
        return TimeSlotProposal(
          startTime: startTime!,
          endTime: startTime.add(Duration(minutes: widget.sessionDuration)),
        );
      }).toList();

      final request = ProposeSlotsRequest(timeSlots: timeSlots);

      // Use the proposeTimeSlots method for rescheduling
      // The backend should handle this as a reschedule based on session status
      await widget.repository.proposeTimeSlots(widget.sessionId, request);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onRescheduled();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session rescheduled successfully. New time slots proposed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reschedule: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reschedule Session',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
              const SizedBox(height: 8),
              Text(
                'Select 1-3 alternative time slots for rescheduling',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Reason field (optional)
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Why do you need to reschedule?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Time slot 1
              _buildTimeSlotCard(0, dateFormat, timeFormat),
              const SizedBox(height: 16),

              // Time slot 2
              _buildTimeSlotCard(1, dateFormat, timeFormat),
              const SizedBox(height: 16),

              // Time slot 3
              _buildTimeSlotCard(2, dateFormat, timeFormat),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReschedule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Propose New Times'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(int index, DateFormat dateFormat, DateFormat timeFormat) {
    final startTime = _startTimes[index];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _selectDateTime(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: startTime != null ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  startTime != null ? Icons.check_circle : Icons.schedule,
                  color: startTime != null ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Slot ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startTime != null
                          ? '${dateFormat.format(startTime)}\n${timeFormat.format(startTime)} - ${timeFormat.format(startTime.add(Duration(minutes: widget.sessionDuration)))}'
                          : 'Tap to select date and time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: startTime != null ? Colors.black87 : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
