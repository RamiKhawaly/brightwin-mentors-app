import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/repositories/cv_auth_repository.dart';

class CVUploadPage extends StatefulWidget {
  const CVUploadPage({super.key});

  @override
  State<CVUploadPage> createState() => _CVUploadPageState();
}

class _CVUploadPageState extends State<CVUploadPage> {
  File? _selectedFile;
  bool _isLoading = false;
  String? _errorMessage;

  late final CVAuthRepository _repository;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = CVAuthRepository(dioClient);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadCV() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a CV file';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Uploading CV...');
      final response = await _repository.uploadCV(_selectedFile!, 'MENTOR');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to approval page with extracted data
      context.push('/cv-auth/approve', extra: response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to upload CV: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register with CV'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.upload_file,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Upload Your CV',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ll extract your information from your CV and create your mentor profile automatically.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedFile != null ? Theme.of(context).primaryColor : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    if (_selectedFile != null) ...[
                      Icon(Icons.check_circle, size: 48, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 12),
                      Text(_selectedFile!.path.split('/').last, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB', style: Theme.of(context).textTheme.bodySmall),
                    ] else ...[
                      Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No file selected', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Supported formats: PDF, DOC, DOCX', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedFile != null ? 'Change File' : 'Select File'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(text: 'Upload & Continue', onPressed: _uploadCV, isLoading: _isLoading, icon: Icons.arrow_forward),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.pop(), child: const Text('Back to Sign In')),
            ],
          ),
        ),
      ),
    );
  }
}
