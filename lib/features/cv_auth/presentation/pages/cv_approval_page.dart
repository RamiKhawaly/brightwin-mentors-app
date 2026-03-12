import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/cv_extraction_response.dart';
import '../../data/models/cv_approval_request.dart';
import '../../data/repositories/cv_auth_repository.dart';

class CVApprovalPage extends StatefulWidget {
  final CVExtractionResponse extractedData;

  const CVApprovalPage({super.key, required this.extractedData});

  @override
  State<CVApprovalPage> createState() => _CVApprovalPageState();
}

class _CVApprovalPageState extends State<CVApprovalPage> {
  bool _isLoading = false;
  String? _errorMessage;
  late final CVAuthRepository _repository;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = CVAuthRepository(dioClient);
  }

  Future<void> _handleApproval(bool approved) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Sending approval: $approved for session: ${widget.extractedData.sessionId}');

      final request = CVApprovalRequest(
        sessionId: widget.extractedData.sessionId,
        approved: approved,
        rejectionReason: approved ? null : 'User rejected extracted data',
      );

      final response = await _repository.approveExtraction(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (approved) {
        // Navigate to OTP verification
        context.push('/cv-auth/otp-verify', extra: {
          'sessionId': widget.extractedData.sessionId,
          'email': widget.extractedData.extractedEmail,
        });
      } else {
        // Go back to upload page
        context.go('/cv-auth/upload');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to process approval: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.extractedData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Information'),
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
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please review the information we extracted from your CV. You can edit any field if needed.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Parsing Status Indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: data.parsingStatus == 'SUCCESS'
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: data.parsingStatus == 'SUCCESS'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.parsingStatus == 'SUCCESS'
                          ? Icons.check_circle
                          : Icons.info,
                      color: data.parsingStatus == 'SUCCESS'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.parsingStatus == 'SUCCESS'
                                ? 'Successfully Extracted'
                                : 'Partial Extraction',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data.parsingStatus == 'SUCCESS'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
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

              // Extracted Information
              _buildInfoCard(
                'Full Name',
                data.extractedFullName,
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Email',
                data.extractedEmail,
                Icons.email,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Phone',
                data.extractedPhone,
                Icons.phone,
              ),
              if (data.extractedAddress != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Address',
                  data.extractedAddress!,
                  Icons.location_on,
                ),
              ],
              if (data.currentJobTitle != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Current Job Title',
                  data.currentJobTitle!,
                  Icons.work,
                ),
              ],
              if (data.professionalSummary != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Professional Summary',
                  data.professionalSummary!,
                  Icons.description,
                  maxLines: 5,
                ),
              ],
              if (data.extractedSkills != null && data.extractedSkills!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Skills',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.extractedSkills!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

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

              // Action Buttons
              CustomButton(
                text: 'Approve & Continue',
                onPressed: () => _handleApproval(true),
                isLoading: _isLoading,
                icon: Icons.check,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _handleApproval(false),
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

  Widget _buildInfoCard(String label, String value, IconData icon, {int maxLines = 2}) {
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
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
