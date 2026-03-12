import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/job_import_response.dart';

class ReviewJobPage extends StatefulWidget {
  final JobImportResponse jobData;

  const ReviewJobPage({super.key, required this.jobData});

  @override
  State<ReviewJobPage> createState() => _ReviewJobPageState();
}

class _ReviewJobPageState extends State<ReviewJobPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _locationController;
  late TextEditingController _minSalaryController;
  late TextEditingController _maxSalaryController;
  late TextEditingController _referralBonusController;

  List<String> _skills = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.jobData.title);
    _companyController = TextEditingController(text: widget.jobData.company);
    _descriptionController = TextEditingController(text: widget.jobData.description);
    _requirementsController = TextEditingController(text: widget.jobData.requirements);
    _locationController = TextEditingController(text: widget.jobData.location ?? '');
    _minSalaryController = TextEditingController(
      text: widget.jobData.minSalary?.toString() ?? '',
    );
    _maxSalaryController = TextEditingController(
      text: widget.jobData.maxSalary?.toString() ?? '',
    );
    _referralBonusController = TextEditingController(text: '5000');
    _skills = List.from(widget.jobData.skills);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _referralBonusController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Call actual API to create job
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate success
        context.pop(true);
      }
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Job Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                        'AI extracted the following details. Review and edit if needed.',
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
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Company',
                        controller: _companyController,
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInfoChip('Type', _formatEnumValue(widget.jobData.jobType)),
                      const SizedBox(height: 8),
                      _buildInfoChip('Level', _formatEnumValue(widget.jobData.level)),
                      const SizedBox(height: 8),
                      _buildInfoChip('Location Type', _formatEnumValue(widget.jobData.locationType)),
                      const SizedBox(height: 24),

                      // Description Section
                      _buildSectionHeader('Job Description'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 6,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 24),

                      // Requirements Section
                      _buildSectionHeader('Requirements'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Requirements',
                        controller: _requirementsController,
                        maxLines: 6,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 24),

                      // Skills Section
                      _buildSectionHeader('Required Skills'),
                      const SizedBox(height: 16),
                      if (_skills.isEmpty)
                        Text(
                          'No skills detected',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
                              onDeleted: _isEditing ? () => _removeSkill(entry.key) : null,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Location & Salary Section
                      _buildSectionHeader('Location & Compensation'),
                      const SizedBox(height: 16),
                      if (widget.jobData.location != null)
                        CustomTextField(
                          label: 'Location',
                          controller: _locationController,
                          enabled: _isEditing,
                        ),
                      if (widget.jobData.location != null) const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Min Salary (${widget.jobData.currency})',
                              controller: _minSalaryController,
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'Max Salary (${widget.jobData.currency})',
                              controller: _maxSalaryController,
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Referral Bonus (NIS)',
                        controller: _referralBonusController,
                        keyboardType: TextInputType.number,
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Source URL
                      _buildSectionHeader('Source'),
                      const SizedBox(height: 8),
                      Text(
                        widget.jobData.sourceUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                      ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: () => context.pop(false),
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Approve & Post',
                        onPressed: _handleApprove,
                        isLoading: _isLoading,
                        icon: Icons.check_circle,
                      ),
                    ),
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

  Widget _buildInfoChip(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  String _formatEnumValue(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
