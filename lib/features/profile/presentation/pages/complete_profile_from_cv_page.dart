import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/profile_preview_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'profile_preview_approval_page.dart';

/// Initial page for completing profile from CV
/// This page allows mentors to upload their CV and initiate the AI extraction process
class CompleteProfileFromCVPage extends StatefulWidget {
  const CompleteProfileFromCVPage({super.key});

  @override
  State<CompleteProfileFromCVPage> createState() => _CompleteProfileFromCVPageState();
}

class _CompleteProfileFromCVPageState extends State<CompleteProfileFromCVPage> {
  late final ProfileRepositoryImpl _profileRepository;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _profileRepository = ProfileRepositoryImpl(dioClient);
  }

  Future<void> _pickAndExtractCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _extractProfileFromCV(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extractProfileFromCV(File cvFile) async {
    setState(() {
      _isProcessing = true;
    });

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Analyzing your CV with AI...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This may take up to 2 minutes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final extractedProfile = await _profileRepository.extractProfileFromCV(cvFile);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      setState(() {
        _isProcessing = false;
      });

      // Navigate to preview and approval page
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePreviewApprovalPage(
            profilePreview: extractedProfile,
          ),
        ),
      );

      if (result == true && mounted) {
        // Profile was saved successfully
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Complete Profile with AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Upload your CV and our AI will automatically extract and structure your professional information',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Features list
              _buildFeatureItem(
                Icons.work_outline,
                'Work Experience',
                'Automatically extract your work history with roles, companies, and achievements',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.school_outlined,
                'Education',
                'Capture your educational background including degrees and institutions',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.star_outline,
                'Skills',
                'Identify and categorize your technical and professional skills',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.analytics_outlined,
                'AI Analysis',
                'Get insights about your profile strengths and improvement suggestions',
              ),
              const SizedBox(height: 40),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'What happens next?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Upload your CV (PDF, DOC, or DOCX)\n'
                      '2. AI extracts and structures your information\n'
                      '3. Review and edit the extracted data\n'
                      '4. Save to complete your profile',
                      style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Upload button
              CustomButton(
                text: 'Upload CV',
                onPressed: _isProcessing ? () {} : _pickAndExtractCV,
                isLoading: _isProcessing,
                icon: Icons.upload_file,
              ),
              const SizedBox(height: 12),
              Text(
                'Supported formats: PDF, DOC, DOCX',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
