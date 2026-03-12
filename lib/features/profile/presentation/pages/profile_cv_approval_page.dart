import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/profile_cv_extraction_model.dart';
import '../../data/models/update_profile_request_model.dart';

class ProfileCVApprovalPage extends StatefulWidget {
  final ProfileCVExtractionModel extractedData;
  final Function(UpdateProfileRequestModel) onApprove;
  final VoidCallback onReject;

  const ProfileCVApprovalPage({
    super.key,
    required this.extractedData,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ProfileCVApprovalPage> createState() => _ProfileCVApprovalPageState();
}

class _ProfileCVApprovalPageState extends State<ProfileCVApprovalPage> {
  bool _isEditMode = false;
  bool _isProcessing = false;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _workEmailController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkedInController;
  late final TextEditingController _githubController;
  late final TextEditingController _portfolioController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _companyController;
  late final TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();

    final nameParts = widget.extractedData.splitName;

    _firstNameController = TextEditingController(text: nameParts['firstName']);
    _lastNameController = TextEditingController(text: nameParts['lastName']);
    _phoneController = TextEditingController(text: widget.extractedData.extractedPhone ?? '');
    _workEmailController = TextEditingController(text: widget.extractedData.extractedEmail ?? '');
    _bioController = TextEditingController(text: widget.extractedData.professionalSummary ?? '');
    _locationController = TextEditingController(text: widget.extractedData.extractedAddress ?? '');
    _linkedInController = TextEditingController(text: widget.extractedData.linkedInUrl ?? '');
    _githubController = TextEditingController(text: widget.extractedData.githubUrl ?? '');
    _portfolioController = TextEditingController(text: widget.extractedData.portfolioUrl ?? '');
    _jobTitleController = TextEditingController(text: widget.extractedData.currentJobTitle ?? '');
    _companyController = TextEditingController(text: widget.extractedData.currentCompany ?? '');
    _experienceController = TextEditingController(text: widget.extractedData.totalYearsOfExperience?.toString() ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _workEmailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _handleApprove() {
    setState(() {
      _isProcessing = true;
    });

    final request = UpdateProfileRequestModel(
      firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
      lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      workEmail: _workEmailController.text.trim().isNotEmpty ? _workEmailController.text.trim() : null,
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      linkedInUrl: _linkedInController.text.trim().isNotEmpty ? _linkedInController.text.trim() : null,
      githubUrl: _githubController.text.trim().isNotEmpty ? _githubController.text.trim() : null,
      portfolioUrl: _portfolioController.text.trim().isNotEmpty ? _portfolioController.text.trim() : null,
      currentJobTitle: _jobTitleController.text.trim().isNotEmpty ? _jobTitleController.text.trim() : null,
      yearsOfExperience: _experienceController.text.trim().isNotEmpty ? int.tryParse(_experienceController.text.trim()) : null,
    );

    widget.onApprove(request);
  }

  void _handleReject() {
    setState(() {
      _isProcessing = true;
    });

    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.extractedData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Profile'),
        actions: [
          if (!_isEditMode && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              tooltip: 'Edit extracted information',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.preview,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Confirm Your Details',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Review and edit the information extracted from your CV before updating your profile.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Parsing Status Indicator
              if (data.parsingStatus != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data.isExtractionSuccessful ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: data.isExtractionSuccessful ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        data.isExtractionSuccessful ? Icons.check_circle : Icons.info,
                        color: data.isExtractionSuccessful ? Colors.green[700] : Colors.orange[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.isExtractionSuccessful ? 'Successfully Extracted' : 'Partial Extraction',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: data.isExtractionSuccessful ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                            if (data.parsingConfidence != null)
                              Text(
                                'Confidence: ${(data.parsingConfidence! * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              if (_isEditMode) ...[
                CustomTextField(
                  label: 'First Name',
                  controller: _firstNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Work Email',
                  controller: _workEmailController,
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                ),
              ] else ...[
                _buildInfoCard('First Name', _firstNameController.text, Icons.person),
                const SizedBox(height: 12),
                _buildInfoCard('Last Name', _lastNameController.text, Icons.person),
                const SizedBox(height: 12),
                _buildInfoCard('Phone', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not extracted', Icons.phone),
                const SizedBox(height: 12),
                _buildInfoCard('Work Email', _workEmailController.text.isNotEmpty ? _workEmailController.text : 'Not extracted', Icons.email),
              ],
              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionHeader('Professional Information'),
              const SizedBox(height: 16),
              if (_isEditMode) ...[
                CustomTextField(
                  label: 'Current Job Title',
                  controller: _jobTitleController,
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Current Company',
                  controller: _companyController,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Years of Experience',
                  controller: _experienceController,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Location',
                  controller: _locationController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ] else ...[
                _buildInfoCard('Job Title', _jobTitleController.text.isNotEmpty ? _jobTitleController.text : 'Not extracted', Icons.work),
                const SizedBox(height: 12),
                _buildInfoCard('Company', _companyController.text.isNotEmpty ? _companyController.text : 'Not extracted', Icons.business),
                const SizedBox(height: 12),
                _buildInfoCard('Experience', _experienceController.text.isNotEmpty ? '${_experienceController.text} years' : 'Not extracted', Icons.calendar_today),
                const SizedBox(height: 12),
                _buildInfoCard('Location', _locationController.text.isNotEmpty ? _locationController.text : 'Not extracted', Icons.location_on),
              ],
              const SizedBox(height: 24),

              // Professional Summary Section
              _buildSectionHeader('Professional Summary'),
              const SizedBox(height: 16),
              if (_isEditMode)
                CustomTextField(
                  label: 'Bio / Professional Summary',
                  controller: _bioController,
                  maxLines: 5,
                  hint: 'Your professional summary...',
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _bioController.text.isNotEmpty ? _bioController.text : 'No professional summary extracted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 24),

              // Social Links Section
              _buildSectionHeader('Social Links'),
              const SizedBox(height: 16),
              if (_isEditMode) ...[
                CustomTextField(
                  label: 'LinkedIn URL',
                  controller: _linkedInController,
                  prefixIcon: const Icon(Icons.link),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'GitHub URL',
                  controller: _githubController,
                  prefixIcon: const Icon(Icons.link),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Portfolio URL',
                  controller: _portfolioController,
                  prefixIcon: const Icon(Icons.link),
                  keyboardType: TextInputType.url,
                ),
              ] else ...[
                _buildInfoCard('LinkedIn', _linkedInController.text.isNotEmpty ? _linkedInController.text : 'Not extracted', Icons.link),
                const SizedBox(height: 12),
                _buildInfoCard('GitHub', _githubController.text.isNotEmpty ? _githubController.text : 'Not extracted', Icons.link),
                const SizedBox(height: 12),
                _buildInfoCard('Portfolio', _portfolioController.text.isNotEmpty ? _portfolioController.text : 'Not extracted', Icons.link),
              ],
              const SizedBox(height: 24),

              // Skills Section (if available)
              if (data.extractedSkills != null && data.extractedSkills!.isNotEmpty) ...[
                _buildSectionHeader('Extracted Skills'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.extractedSkills!.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              if (_isEditMode) ...[
                CustomButton(
                  text: 'Done Editing',
                  onPressed: () {
                    setState(() {
                      _isEditMode = false;
                    });
                  },
                  icon: Icons.check,
                ),
                const SizedBox(height: 16),
              ],

              CustomButton(
                text: 'Approve & Update Profile',
                onPressed: _isProcessing ? () {} : _handleApprove,
                isLoading: _isProcessing,
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handleReject,
                icon: const Icon(Icons.close),
                label: const Text('Reject & Re-upload'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.shade300),
                  foregroundColor: Colors.red.shade700,
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
