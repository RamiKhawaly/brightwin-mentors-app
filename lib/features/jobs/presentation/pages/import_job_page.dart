import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/job_import_request.dart';
import '../../data/repositories/job_repository_impl.dart';

class ImportJobPage extends StatefulWidget {
  const ImportJobPage({super.key});

  @override
  State<ImportJobPage> createState() => _ImportJobPageState();
}

class _ImportJobPageState extends State<ImportJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late final JobRepositoryImpl _jobRepository;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _jobRepository = JobRepositoryImpl(dioClient);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a job URL';
    }

    // Basic URL validation
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  Future<void> _handleImport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final request = JobImportRequest(url: _urlController.text.trim());
        print('========================================');
        print('Sending job URL to backend: ${_urlController.text}');
        print('Request JSON: ${request.toJson()}');
        print('========================================');
        final response = await _jobRepository.importJobFromUrl(request);
        print('========================================');
        print('Response received from backend:');
        print('Job ID: ${response.id}');
        print('Job Title: ${response.title}');
        print('Company: ${response.company}');
        print('Status: ${response.status}');
        print('========================================');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          final result = await context.push<bool>(
            '/job-review-extracted',
            extra: response,
          );

          if (result == true && mounted) {
            context.pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to import job. Please check the URL and try again.\n${e.toString()}';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Job from URL'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Card(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick Job Import',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Paste a job URL and our AI will extract all the details for you. You can review and edit before posting.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // URL Input
                      CustomTextField(
                        label: 'Job URL',
                        hint: 'https://example.com/jobs/123',
                        controller: _urlController,
                        validator: _validateUrl,
                        keyboardType: TextInputType.url,
                        prefixIcon: const Icon(Icons.link),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: 'Import Job',
                    onPressed: _handleImport,
                    isLoading: _isLoading,
                    icon: Icons.cloud_download,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Or create manually'),
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

  Widget _buildPlatformChip(String platform) {
    return Chip(
      label: Text(
        platform,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
