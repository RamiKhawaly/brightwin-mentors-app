import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/job_request_model.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/usecases/create_job_usecase.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxApplicationsController = TextEditingController();

  JobType _selectedJobType = JobType.fullTime;
  JobLevel _selectedLevel = JobLevel.mid;
  JobLocation _selectedLocationType = JobLocation.hybrid;

  final List<String> _selectedSkills = [];
  final TextEditingController _skillController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;

  late final CreateJobUseCase _createJobUseCase;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    final repository = JobRepositoryImpl(dioClient);
    _createJobUseCase = CreateJobUseCase(repository);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _maxApplicationsController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _selectedSkills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _selectedSkills.removeAt(index);
    });
  }

  String _mapJobTypeToApiString(JobType type) {
    switch (type) {
      case JobType.fullTime:
        return 'FULL_TIME';
      case JobType.partTime:
        return 'PART_TIME';
      case JobType.contract:
        return 'CONTRACT';
      case JobType.internship:
        return 'INTERNSHIP';
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create the job request model
        final request = JobRequestModel(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          company: _companyController.text.trim(),
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          employmentType: _mapJobTypeToApiString(_selectedJobType),
          techStack: _selectedSkills.isNotEmpty ? _selectedSkills : null,
          maxApplications: _maxApplicationsController.text.trim().isNotEmpty 
              ? int.tryParse(_maxApplicationsController.text.trim()) 
              : null,
        );

        // Call the use case to create the job
        await _createJobUseCase(request);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to post job: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Job Title',
          hint: 'e.g., Senior Flutter Developer',
          controller: _titleController,
          validator: (value) => _validateRequired(value, 'job title'),
          prefixIcon: const Icon(Icons.work_outline),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Company Name',
          hint: 'Your company name',
          controller: _companyController,
          validator: (value) => _validateRequired(value, 'company name'),
          prefixIcon: const Icon(Icons.business_outlined),
        ),
        const SizedBox(height: 16),
        Text(
          'Job Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<JobType>(
          value: _selectedJobType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.schedule_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: JobType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_formatEnumValue(type.toString())),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedJobType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Experience Level',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<JobLevel>(
          value: _selectedLevel,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.stairs_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: JobLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(_formatEnumValue(level.toString())),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLevel = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildJobDetailsStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Job Description',
          hint: 'Describe the role and responsibilities...',
          controller: _descriptionController,
          validator: (value) => _validateRequired(value, 'job description'),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Requirements',
          hint: 'List the requirements and qualifications...',
          controller: _requirementsController,
          validator: (value) => _validateRequired(value, 'requirements'),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        Text(
          'Required Skills',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: InputDecoration(
                  hintText: 'Add a skill',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addSkill,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedSkills.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeSkill(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        Text(
          'Work Location Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<JobLocation>(
          value: _selectedLocationType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: JobLocation.values.map((location) {
            return DropdownMenuItem(
              value: location,
              child: Text(_formatEnumValue(location.toString())),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLocationType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        if (_selectedLocationType != JobLocation.remote)
          CustomTextField(
            label: 'Location',
            hint: 'e.g., Tel Aviv, Israel',
            controller: _locationController,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Application Limit (Optional)',
          hint: 'Max number of applications (leave empty for unlimited)',
          controller: _maxApplicationsController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.people_outline),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final num = int.tryParse(value);
              if (num == null || num <= 0) {
                return 'Please enter a valid positive number';
              }
            }
            return null;
          },
          ),
      ],
    );
  }

  String _formatEnumValue(String value) {
    return value.split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        ).trim().replaceFirst(
          value.split('.').last[0],
          value.split('.').last[0].toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Stepper indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _currentStep == 0
                      ? _buildBasicInfoStep()
                      : _currentStep == 1
                          ? _buildJobDetailsStep()
                          : _buildLocationStep(),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Back',
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                          isOutlined: true,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: _currentStep < 2 ? 'Next' : 'Post Job',
                        onPressed: () {
                          if (_currentStep < 2) {
                            setState(() {
                              _currentStep++;
                            });
                          } else {
                            _handleSubmit();
                          }
                        },
                        isLoading: _isLoading,
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
}
