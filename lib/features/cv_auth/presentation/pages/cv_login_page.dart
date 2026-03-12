import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/repositories/cv_auth_repository.dart';

class CVLoginPage extends StatefulWidget {
  const CVLoginPage({super.key});

  @override
  State<CVLoginPage> createState() => _CVLoginPageState();
}

class _CVLoginPageState extends State<CVLoginPage> {
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

  Future<void> _loginWithCV() async {
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
      print('Logging in with CV...');
      final response = await _repository.loginWithCV(_selectedFile!);

      if (!mounted) return;

      // Store tokens
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'access_token', value: response.accessToken);
      await storage.write(key: 'refresh_token', value: response.refreshToken);
      await storage.write(key: 'user_id', value: response.userId);
      await storage.write(key: 'user_role', value: response.role);

      setState(() {
        _isLoading = false;
      });

      // Navigate to home
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to login with CV: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with CV'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.fingerprint,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Login with Your CV',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Upload the same CV you registered with. We\'ll securely verify your identity using the document.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Security Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Login',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We use your CV\'s unique contact information (phone, email, ID, address) to verify your identity. Your CV is never stored permanently.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // File Selection Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    if (_selectedFile != null) ...[
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No file selected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supported formats: PDF, DOC, DOCX',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Login',
                onPressed: _loginWithCV,
                isLoading: _isLoading,
                icon: Icons.login,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Sign In'),
              ),
              const SizedBox(height: 24),

              // First time user prompt
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'First time here?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register with your CV to create an account',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.push('/cv-auth/upload'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register with CV'),
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
