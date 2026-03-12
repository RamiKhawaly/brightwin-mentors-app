import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/environment_service.dart';
import '../../../../core/config/router_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/login_request_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String password;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _timer;

  late final DioClient _dioClient;
  late final AuthRepositoryImpl _authRepository;
  final _environmentService = EnvironmentService();

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _startResendCountdown();
  }

  Future<void> _initializeAuth() async {
    await _environmentService.initialize();
    final storage = const FlutterSecureStorage();
    _dioClient = DioClient(storage);
    _authRepository = AuthRepositoryImpl(_dioClient, storage, _environmentService);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify OTP
      await _dioClient.dio.post(
        '/api/auth/otp/verify',
        data: {
          'email': widget.email,
          'otpCode': otp,
        },
      );

      if (!mounted) return;

      // Auto-login after successful verification
      try {
        final loginRequest = LoginRequestModel(
          email: widget.email,
          password: widget.password,
        );

        await _authRepository.login(loginRequest);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified! Welcome to Brightwin!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to mentor onboarding for first-time users
          context.go(AppRoutes.mentorOnboarding);
        }
      } catch (loginError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification successful! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go(AppRoutes.signIn);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        // Auto-regenerate OTP on verification failure
        await _regenerateOtp();

        setState(() {
          _isLoading = false;
          _errorMessage = e.response?.data['message'] ??
                          'Invalid OTP code. A new code has been sent to your email.';
        });

        // Clear the OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  Future<void> _regenerateOtp() async {
    try {
      await _dioClient.dio.post(
        '/api/auth/otp/resend',
        data: {
          'email': widget.email,
          'purpose': 'verify your email',
        },
      );
      _startResendCountdown();
    } catch (e) {
      // Silent fail - already showing error message
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await _dioClient.dio.post(
        '/api/auth/otp/resend',
        data: {
          'email': widget.email,
          'purpose': 'verify your email',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP code resent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCountdown();
        setState(() {
          _isResending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  'Enter the 6-digit code sent to',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Error Message
                if (_errorMessage != null) ...[
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitChanged(index, value),
                        onTap: () {
                          if (_controllers[index].text.isNotEmpty) {
                            _controllers[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _controllers[index].text.length,
                            );
                          }
                        },
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Verify Button
                CustomButton(
                  text: 'Verify Email',
                  onPressed: _isLoading ? () {} : _verifyOtp,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 24),

                // Resend OTP
                if (_resendCountdown > 0)
                  Text(
                    'Resend code in $_resendCountdown seconds',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  )
                else
                  TextButton(
                    onPressed: _isResending ? null : _resendOtp,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Resend Code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                const SizedBox(height: 16),

                // Back to Sign In
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(AppRoutes.signIn),
                  child: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
