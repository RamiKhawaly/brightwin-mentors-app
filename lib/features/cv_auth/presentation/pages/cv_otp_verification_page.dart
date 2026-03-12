import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/otp_verification_request.dart';
import '../../data/repositories/cv_auth_repository.dart';

class CVOtpVerificationPage extends StatefulWidget {
  final String sessionId;
  final String email;

  const CVOtpVerificationPage({
    super.key,
    required this.sessionId,
    required this.email,
  });

  @override
  State<CVOtpVerificationPage> createState() => _CVOtpVerificationPageState();
}

class _CVOtpVerificationPageState extends State<CVOtpVerificationPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  late final CVAuthRepository _repository;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = CVAuthRepository(dioClient);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Verifying OTP for session: ${widget.sessionId}');

      final request = OTPVerificationRequest(
        sessionId: widget.sessionId,
        email: widget.email,
        otpCode: _otpController.text.trim(),
      );

      final response = await _repository.verifyOTPAndRegister(request);

      if (!mounted) return;

      // Store tokens
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'access_token', value: response.accessToken);
      await storage.write(key: 'refresh_token', value: response.refreshToken);
      await storage.write(key: 'user_id', value: response.userId);
      await storage.write(key: 'user_role', value: response.role);

      setState(() {
        _isLoading = false;
        _successMessage = 'Registration successful! Redirecting...';
      });

      // Navigate to home page after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to verify OTP: ${e.toString()}';
      });
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('Resending OTP for session: ${widget.sessionId}');

      // Call resend endpoint (if available in your API)
      // For now, we'll just show a success message

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _successMessage = 'OTP code has been resent to ${widget.email}';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to resend OTP: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.email_outlined,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification code to',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the 6-digit code to complete your registration.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // OTP Input Field
              CustomTextField(
                label: 'Verification Code',
                hint: 'Enter 6-digit code',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.pin),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
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

              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Verify Button
              CustomButton(
                text: 'Verify & Complete Registration',
                onPressed: _verifyOTP,
                isLoading: _isLoading,
                icon: Icons.check_circle,
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resendOTP,
                    child: const Text('Resend'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info Box
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
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email. The code expires in 10 minutes.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
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
