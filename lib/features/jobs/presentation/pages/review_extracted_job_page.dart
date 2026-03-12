import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/job_request_model.dart';
import '../../data/models/job_response_model.dart';
import '../../data/repositories/job_repository_impl.dart';

class ReviewExtractedJobPage extends StatefulWidget {
  final JobResponseModel jobData;

  const ReviewExtractedJobPage({super.key, required this.jobData});

  @override
  State<ReviewExtractedJobPage> createState() => _ReviewExtractedJobPageState();
}

class _ReviewExtractedJobPageState extends State<ReviewExtractedJobPage> {
  bool _isLoading = false;
  bool _isEditMode = true; // Start in edit mode by default
  String _loadingMessage = '';
  late final JobRepositoryImpl _jobRepository;

  // Edit controllers
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _maxApplicationsController;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _jobRepository = JobRepositoryImpl(dioClient);

    // Initialize controllers with job data
    _titleController = TextEditingController(text: widget.jobData.title);
    _companyController = TextEditingController(text: widget.jobData.company);
    _descriptionController = TextEditingController(text: widget.jobData.description);
    _locationController = TextEditingController(text: widget.jobData.location ?? '');
    _maxApplicationsController = TextEditingController(
      text: widget.jobData.maxApplications?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxApplicationsController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving changes...';
    });

    try {
      // Create job request with updated data
      final request = JobRequestModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        employmentType: widget.jobData.employmentType,
        techStack: widget.jobData.techStack,
        salaryMin: widget.jobData.salaryMin,
        salaryMax: widget.jobData.salaryMax,
        salaryCurrency: widget.jobData.salaryCurrency,
        referralBonus: widget.jobData.referralBonus,
        externalUrl: widget.jobData.externalUrl,
        maxApplications: _maxApplicationsController.text.trim().isNotEmpty
            ? int.tryParse(_maxApplicationsController.text.trim())
            : null,
      );

      // Update the job without changing status
      await _jobRepository.updateJob(widget.jobData.id, request);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
          _isEditMode = false; // Exit edit mode
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${_titleController.text}" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate changes were saved
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePublish() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Publishing job...';
    });

    try {
      // First save any changes
      final request = JobRequestModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        employmentType: widget.jobData.employmentType,
        techStack: widget.jobData.techStack,
        salaryMin: widget.jobData.salaryMin,
        salaryMax: widget.jobData.salaryMax,
        salaryCurrency: widget.jobData.salaryCurrency,
        referralBonus: widget.jobData.referralBonus,
        externalUrl: widget.jobData.externalUrl,
        maxApplications: _maxApplicationsController.text.trim().isNotEmpty
            ? int.tryParse(_maxApplicationsController.text.trim())
            : null,
      );

      await _jobRepository.updateJob(widget.jobData.id, request);

      if (!mounted) return;

      // Then publish the job
      await _jobRepository.publishJob(widget.jobData.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${_titleController.text}" published successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate job was published
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
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

  void _handleEdit() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _handleReject() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job?'),
        content: const Text('Are you sure you want to reject this job? It will be deleted.'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await _jobRepository.rejectJob(widget.jobData.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job rejected and deleted'),
            backgroundColor: Colors.orange,
          ),
        );

        // Return false to indicate rejection
        context.pop(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject job: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Job Details'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI extracted the following details. Review and edit them, then save as draft or publish directly.',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Job Title',
                      controller: _titleController,
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Company',
                      controller: _companyController,
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Employment Type', widget.jobData.employmentType ?? 'Not specified'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Location',
                      controller: _locationController,
                      hint: 'e.g., Tel Aviv, Remote',
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    _buildSectionHeader('Job Description'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 24),

                    // Skills Section
                    if (widget.jobData.techStack != null && widget.jobData.techStack!.isNotEmpty) ...[
                      _buildSectionHeader('Required Skills'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.jobData.techStack!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Salary Section
                    if (widget.jobData.salaryMin != null || widget.jobData.salaryMax != null) ...[
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
                              '${widget.jobData.salaryMin?.toStringAsFixed(0) ?? '0'} - ${widget.jobData.salaryMax?.toStringAsFixed(0) ?? '0'} ${widget.jobData.salaryCurrency ?? 'NIS'}',
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

                    // Application Limit Section
                    _buildSectionHeader('Application Settings'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Max Applications (Optional)',
                      hint: 'Leave empty for unlimited',
                      controller: _maxApplicationsController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.people_outline),
                    ),
                    const SizedBox(height: 24),

                    // Source URL
                    if (widget.jobData.externalUrl != null) ...[
                      _buildSectionHeader('Source'),
                      const SizedBox(height: 8),
                      Text(
                        widget.jobData.externalUrl!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loading indicator with message
                  if (_isLoading && _loadingMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingMessage,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Action buttons (always show these three)
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: _isLoading ? () {} : () {
                            // Show confirmation dialog before canceling
                            showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Import?'),
                                content: const Text('Are you sure you want to cancel? All changes will be lost and the job will be deleted.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('No, keep editing'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Yes, cancel'),
                                  ),
                                ],
                              ),
                            ).then((confirmed) async {
                              if (confirmed == true) {
                                // Delete the job and go back
                                try {
                                  await _jobRepository.rejectJob(widget.jobData.id);
                                  if (mounted) {
                                    context.pop(false);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to cancel: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            });
                          },
                          isOutlined: true,
                          icon: Icons.close,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Save as Draft',
                          onPressed: _isLoading ? () {} : _handleSaveChanges,
                          icon: Icons.save_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Publish',
                    onPressed: _isLoading ? () {} : _handlePublish,
                    icon: Icons.publish,
                  ),
                ],
              ),
            ),
          ],
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
}
