import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';
import '../widgets/application_status_flow.dart';
import '../../../sessions/presentation/pages/candidate_profile_viewer_page.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/data/models/user_profile_response_model.dart';
import 'cv_viewer_page.dart';

class ApplicationDetailPage extends StatefulWidget {
  final ApplicationModel application;

  const ApplicationDetailPage({
    super.key,
    required this.application,
  });

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  late final ApplicationsRepository _repository;
  late final ProfileRepositoryImpl _profileRepository;
  late ApplicationModel _application;
  bool _isLoading = false;
  UserProfileResponseModel? _userProfile;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = ApplicationsRepository(dioClient);
    _profileRepository = ProfileRepositoryImpl(dioClient);
    _application = widget.application;

    // Log CV information on page load
    print('🔍 [CV DEBUG] ApplicationDetailPage initialized');
    print('   Application ID: ${_application.id}');
    print('   Candidate: ${_application.candidateName}');
    print('   CV URL value: ${_application.cvUrl}');
    print('   CV URL is null: ${_application.cvUrl == null}');
    print('   CV URL is empty: ${_application.cvUrl?.isEmpty ?? "N/A"}');

    // Load user profile
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load user profile: $e');
      // Continue without profile - user can still enter email manually
    }
  }

  Future<void> _updateStatus(ApplicationStatus newStatus) async {
    // Show confirmation dialog for rejection
    if (newStatus == ApplicationStatus.REJECTED) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Application?'),
          content: const Text(
            'Are you sure you want to reject this application? The candidate will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = UpdateApplicationStatusRequest(
        status: newStatus.apiValue,
      );

      final updatedApplication = await _repository.updateApplicationStatus(
        _application.id,
        request,
      );

      if (mounted) {
        setState(() {
          _application = updatedApplication;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forwardToHR() async {
    // First, show option selection dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you like to proceed?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Option 1: Forward via email
            InkWell(
              onTap: () => Navigator.pop(context, 'forward_email'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.email,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Forward via Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send CV to an email address',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Mark as forwarded
            InkWell(
              onTap: () => Navigator.pop(context, 'manual'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark as Forwarded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update status only (forwarded manually)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'manual') {
      // Just update the status without sending email
      await _updateStatus(ApplicationStatus.FORWARDED_TO_HR);
      return;
    }

    // Show email configuration dialog
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _ForwardEmailDialog(
        workEmail: _userProfile?.workEmail,
        personalEmail: _userProfile?.email,
      ),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = ForwardApplicationRequest(
        recipientEmail: result['email'],
        customMessage: result['message'],
      );

      final updatedApplication = await _repository.forwardApplication(
        _application.id,
        request,
      );

      if (mounted) {
        setState(() {
          _application = updatedApplication;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application forwarded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to forward: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewCandidateProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateProfileViewerPage(
          candidateId: _application.candidateId,
        ),
      ),
    );
  }

  Future<void> _openCV() async {
    print('🔍 [CV DEBUG] _openCV() called');
    print('   Application ID: ${_application.id}');
    print('   CV ID: ${_application.cvId}');
    print('   CV FileName: ${_application.cvFileName}');

    if (_application.cvId == null) {
      print('   ❌ No CV attached to this application');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CV not available for this application'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('   ✅ Opening CV viewer...');

    // Navigate to CV viewer page - uses CV ID
    // Note: /api/cv/download/{cvId} is public so no auth issues
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CVViewerPage(
          cvId: _application.cvId!,
          cvFileName: _application.cvFileName ?? 'CV - ${_application.candidateName}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Flow
                  ApplicationStatusFlow(
                    application: _application,
                    isLoading: _isLoading,
                    onStatusUpdate: (status) {
                      if (status == ApplicationStatus.FORWARDED_TO_HR) {
                        _forwardToHR();
                      } else {
                        _updateStatus(status);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submitted date info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Submitted ${_formatDate(_application.submittedAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Candidate Info Section
                  _buildSectionHeader('Candidate Information'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: _application.candidateImageUrl != null
                                  ? NetworkImage(_application.candidateImageUrl!)
                                  : null,
                              child: _application.candidateImageUrl == null
                                  ? Text(
                                      _application.candidateName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 24),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _application.candidateName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (_application.candidateEmail != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _application.candidateEmail!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_application.candidatePhone != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_outlined,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          _application.candidatePhone!,
                                          style: TextStyle(
                                            fontSize: 14,
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
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // View Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _viewCandidateProfile,
                            icon: const Icon(Icons.person_outline),
                            label: const Text('View Full Profile'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Job Info Section
                  _buildSectionHeader('Applied For'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _application.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _application.jobCompany,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CV Section
                  _buildSectionHeader('Curriculum Vitae'),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      print('🔍 [CV DEBUG] Building CV section');
                      print('   CV URL: ${_application.cvUrl}');
                      print('   Is null: ${_application.cvUrl == null}');
                      print('   Showing CV: ${_application.cvUrl != null}');
                      return const SizedBox.shrink();
                    },
                  ),
                  if (_application.cvUrl != null) ...[
                    InkWell(
                      onTap: _openCV,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 32, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _application.cvFileName ?? 'CV Document',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                  Text(
                                    'Tap to view',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new, color: Colors.green[700]),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Missing CV Warning
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 32, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CV Not Submitted',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'The candidate needs to upload their CV to complete this application',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[800],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Cover Letter Section
                  if (_application.coverLetter != null &&
                      _application.coverLetter!.isNotEmpty) ...[
                    _buildSectionHeader('Cover Letter'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _application.coverLetter!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Auto-Forward Status
                  if (_application.autoForwarded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This application was automatically forwarded to HR',
                              style: TextStyle(
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reject Button (only show if not already rejected/withdrawn)
                  if (_application.status != ApplicationStatus.REJECTED &&
                      _application.status != ApplicationStatus.WITHDRAWN) ...[
                    const Divider(height: 40),
                    CustomButton(
                      text: 'Reject Application',
                      onPressed: _isLoading
                          ? () {}
                          : () => _updateStatus(ApplicationStatus.REJECTED),
                      icon: Icons.cancel_outlined,
                      isOutlined: true,
                    ),
                  ],
                  // Extra bottom padding to avoid system navigation buttons
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }
}

// Forward Email Dialog Widget
class _ForwardEmailDialog extends StatefulWidget {
  final String? workEmail;
  final String? personalEmail;

  const _ForwardEmailDialog({
    this.workEmail,
    this.personalEmail,
  });

  @override
  State<_ForwardEmailDialog> createState() => _ForwardEmailDialogState();
}

class _ForwardEmailDialogState extends State<_ForwardEmailDialog> {
  String _emailType = 'workplace'; // 'workplace' or 'custom'
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate with workplace email or fallback to personal email
    final defaultEmail = widget.workEmail ?? widget.personalEmail ?? '';
    _emailController.text = defaultEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forward Application'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show info about the pre-populated email
            if (widget.workEmail != null || widget.personalEmail != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.workEmail != null
                            ? 'Using your workplace email from profile'
                            : 'Using your personal email (no workplace email in profile)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Select email type:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Workplace Email Option
            RadioListTile<String>(
              title: const Text('My Workplace Email'),
              subtitle: Text(
                widget.workEmail != null
                    ? widget.workEmail!
                    : widget.personalEmail ?? 'Not set in profile',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: 'workplace',
              groupValue: _emailType,
              onChanged: (value) {
                setState(() {
                  _emailType = value!;
                  // Reset to default email
                  _emailController.text = widget.workEmail ?? widget.personalEmail ?? '';
                });
              },
            ),

            // Custom Email Option
            RadioListTile<String>(
              title: const Text('Custom Email'),
              subtitle: const Text(
                'Send to a different email address',
                style: TextStyle(fontSize: 12),
              ),
              value: 'custom',
              groupValue: _emailType,
              onChanged: (value) {
                setState(() {
                  _emailType = value!;
                  // Clear email for custom entry
                  if (_emailController.text == widget.workEmail ||
                      _emailController.text == widget.personalEmail) {
                    _emailController.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Email Input Field
            CustomTextField(
              label: _emailType == 'workplace' ? 'My Workplace Email' : 'Recipient Email',
              hint: 'e.g., your.name@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // Custom Message Field
            CustomTextField(
              label: 'Custom Message (Optional)',
              hint: 'Add a personal note to the forwarding email',
              controller: _messageController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Validate email
            if (_emailController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter an email address'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            // Return result
            Navigator.pop(context, {
              'email': _emailController.text.trim(),
              'message': _messageController.text.trim().isNotEmpty
                  ? _messageController.text.trim()
                  : null,
            });
          },
          icon: const Icon(Icons.send),
          label: const Text('Send Email'),
        ),
      ],
    );
  }
}
