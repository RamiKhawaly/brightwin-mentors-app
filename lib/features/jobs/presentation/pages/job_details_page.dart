import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/job_response_model.dart';
import '../../data/repositories/job_repository_impl.dart';

class JobDetailsPage extends StatefulWidget {
  final JobResponseModel job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late final JobRepositoryImpl _jobRepository;
  late JobResponseModel _job;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    final dioClient = DioClient(const FlutterSecureStorage());
    _jobRepository = JobRepositoryImpl(dioClient);
  }

  Future<void> _handleApprove() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedJob = await _jobRepository.approveJob(_job.id);
      if (mounted) {
        setState(() {
          _job = updatedJob;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${_job.title}" approved!'),
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
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePublish() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedJob = await _jobRepository.publishJob(_job.id);
      if (mounted) {
        setState(() {
          _job = updatedJob;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${_job.title}" published!'),
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
            content: Text('Failed to publish: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnpublish() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedJob = await _jobRepository.unpublishJob(_job.id);
      if (mounted) {
        setState(() {
          _job = updatedJob;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${_job.title}" unpublished!'),
            backgroundColor: Colors.orange,
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
            content: Text('Failed to unpublish: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _jobRepository.deleteJob(_job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate job was deleted
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (_job.status ?? '').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _handleDelete,
            tooltip: 'Delete Job',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header with Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _job.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, color: Colors.white.withOpacity(0.9), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _job.company,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBadge(status),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  _buildSectionHeader('Basic Information'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Employment Type', _job.employmentType ?? 'Not specified'),
                  if (_job.location != null)
                    _buildInfoRow('Location', _job.location!),
                  if (_job.createdAt != null)
                    _buildInfoRow('Posted', _getTimeAgo(_job.createdAt!)),
                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionHeader('Job Description'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _job.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Skills Section
                  if (_job.techStack != null && _job.techStack!.isNotEmpty) ...[
                    _buildSectionHeader('Required Skills'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _job.techStack!.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Salary Section
                  if (_job.salaryMin != null || _job.salaryMax != null) ...[
                    _buildSectionHeader('Compensation'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Text(
                            '${_job.salaryMin?.toStringAsFixed(0) ?? '0'} - ${_job.salaryMax?.toStringAsFixed(0) ?? '0'} ${_job.salaryCurrency ?? 'NIS'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Applications Section
                  _buildSectionHeader('Applications'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Applicants Count Card (Clickable)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Navigate to applications list filtered by this job
                            context.push(
                              '/applications',
                              extra: {
                                'jobId': _job.id,
                                'jobTitle': _job.title,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Applicants',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue[700]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_job.applicationsCount}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  _job.applicationsCount == 1 ? 'application' : 'applications',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Available Spots Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _job.isApplicationLimitReached
                                ? Colors.red[50]
                                : Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _job.isApplicationLimitReached
                                  ? Colors.red[200]!
                                  : Colors.purple[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _job.isApplicationLimitReached
                                        ? Icons.block
                                        : Icons.event_available,
                                    color: _job.isApplicationLimitReached
                                        ? Colors.red[700]
                                        : Colors.purple[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Available Spots',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _job.isApplicationLimitReached
                                            ? Colors.red[700]
                                            : Colors.purple[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _job.maxApplications != null
                                    ? '${_job.remainingSlots ?? 0}'
                                    : '∞',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _job.isApplicationLimitReached
                                      ? Colors.red[900]
                                      : Colors.purple[900],
                                ),
                              ),
                              Text(
                                _job.maxApplications != null
                                    ? 'of ${_job.maxApplications} spots'
                                    : 'unlimited',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _job.isApplicationLimitReached
                                      ? Colors.red[600]
                                      : Colors.purple[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Source URL
                  if (_job.externalUrl != null) ...[
                    _buildSectionHeader('Source'),
                    const SizedBox(height: 8),
                    Text(
                      _job.externalUrl!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(status),
    );
  }

  Widget _buildActionButtons(String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // PENDING_APPROVAL: Show Approve button
            if (status == 'PENDING_APPROVAL') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleApprove,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            // OPEN: Show Unpublish button
            if (status == 'OPEN') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUnpublish,
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Unpublish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            // DRAFT or CLOSED: Show Publish button
            if (status == 'DRAFT' || status == 'CLOSED') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handlePublish,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Publish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'PENDING_APPROVAL':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        displayText = 'Needs Approval';
        break;
      case 'OPEN':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        displayText = 'Published';
        break;
      case 'CLOSED':
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        displayText = 'Closed';
        break;
      case 'DRAFT':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        displayText = 'Draft';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
