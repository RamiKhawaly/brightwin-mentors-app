import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/services/environment_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/models/login_request_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  String _currentEnvironment = 'Development';

  late AuthRepositoryImpl _authRepository;
  final _environmentService = EnvironmentService();

  @override
  void initState() {
    super.initState();
    _initializeEnvironmentAndAuth();
    _loadSavedCredentials();
  }

  Future<void> _initializeEnvironmentAndAuth() async {
    // IMPORTANT: Initialize environment FIRST, before creating DioClient
    await _environmentService.initialize();

    print('🚀 Environment initialized: ${_environmentService.environmentName}');
    print('🌐 Base URL: ${_environmentService.baseUrl}');

    if (mounted) {
      setState(() {
        _currentEnvironment = _environmentService.environmentName;
      });
    }

    // NOW create DioClient after environment is loaded
    final storage = const FlutterSecureStorage();
    final dioClient = DioClient(storage);
    _authRepository = AuthRepositoryImpl(dioClient, storage, _environmentService);

    print('✅ Auth repository initialized with correct environment');
  }

  // LinkedIn Sign-In - Temporarily disabled
  // TODO: Re-enable LinkedIn OAuth when url_launcher and app_links packages are added
  Future<void> _handleLinkedInSignIn() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LinkedIn sign-in is temporarily unavailable'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleEnvironment() async {
    // Toggle the environment
    await _environmentService.toggleEnvironment();

    if (!mounted) return;

    setState(() {
      _currentEnvironment = _environmentService.environmentName;
    });

    // Show snackbar with current environment and URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched to $_currentEnvironment\n${_environmentService.baseUrl}',
        ),
        backgroundColor: _environmentService.isDevelopment ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Reinitialize DioClient with new environment
    final storage = const FlutterSecureStorage();
    final dioClient = DioClient(storage);

    // Create new repository with updated DioClient
    setState(() {
      _authRepository = AuthRepositoryImpl(dioClient, storage, _environmentService);
    });

    print('🔄 Environment switched to ${_environmentService.environmentName}');
    print('📍 New base URL: ${_environmentService.baseUrl}');
  }

  Future<void> _loadSavedCredentials() async {
    try {
      const storage = FlutterSecureStorage();
      final rememberMe = await storage.read(key: 'remember_me');
      final savedEmail = await storage.read(key: 'saved_email');
      final savedPassword = await storage.read(key: 'saved_password');

      if (rememberMe == 'true' && savedEmail != null && savedPassword != null) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      const storage = FlutterSecureStorage();

      if (_rememberMe) {
        await storage.write(key: 'remember_me', value: 'true');
        await storage.write(key: 'saved_email', value: _emailController.text.trim());
        await storage.write(key: 'saved_password', value: _passwordController.text);
        await storage.write(key: 'keep_logged_in', value: 'true');
      } else {
        await storage.delete(key: 'remember_me');
        await storage.delete(key: 'saved_email');
        await storage.delete(key: 'saved_password');
        await storage.write(key: 'keep_logged_in', value: 'false');
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      bool loginSuccessful = false;

      try {
        print('🔐 Attempting login for: ${_emailController.text.trim()}');

        // Call the backend login API
        final request = LoginRequestModel(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final response = await _authRepository.login(request);

        print('✅ Login response received');
        print('Token present: ${response.token.isNotEmpty}');
        print('User: ${response.firstName} ${response.lastName}');

        // Only proceed if login was successful (response received)
        if (response.token.isEmpty) {
          throw Exception('Invalid login response - no token received');
        }

        // Mark login as successful
        loginSuccessful = true;

        // Save credentials if remember me is checked
        await _saveCredentials();

        // Register FCM token with backend
        try {
          print('📱 Registering FCM token with backend...');
          final storage = const FlutterSecureStorage();
          final dioClient = DioClient(storage);
          final registered = await FCMService().registerTokenWithBackend(dioClient);
          if (registered) {
            print('✅ FCM token registered successfully');
          } else {
            print('⚠️ FCM token registration skipped or failed');
          }
        } catch (e) {
          print('⚠️ Error registering FCM token: $e');
          // Continue with login even if FCM registration fails
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Mark onboarding as completed (user already has an account)
        const storage = FlutterSecureStorage();
        await storage.write(key: 'onboarding_completed', value: 'true');
        print('✅ Marked onboarding as completed for existing user');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${response.firstName}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to home - only reached if no exception thrown
        if (mounted && loginSuccessful) {
          print('🏠 Navigating to home screen');
          context.go(AppRoutes.home);
        }
      } catch (e) {
        // Error occurred - do NOT navigate
        print('❌ Login error caught in _handleSignIn: $e');
        print('📍 Login successful flag: $loginSuccessful');

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please check your credentials and try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        // Explicitly return here to ensure no further code executes
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.googleLogin);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: Color(0xFF4285F4),
                        );
                      },
                    ),
                  ),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: Colors.black87,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 16),
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                // Remember Me checkbox and Forgot Password on same line
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Text(
                          'Remember me',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.forgotPassword);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Sign In',
                  onPressed: _handleSignIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                // Register Link
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(AppRoutes.signUp);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Register as a Mentor',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
