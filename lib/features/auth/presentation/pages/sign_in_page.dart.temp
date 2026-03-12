import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/services/environment_service.dart';
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

  // Deep link subscription
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeEnvironmentAndAuth();
    _loadSavedCredentials();
    _initDeepLinkListener();
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

  // Initialize deep link listener for OAuth callback
  Future<void> _initDeepLinkListener() async {
    try {
      // Listen to incoming deep links
      _deepLinkSubscription = uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }, onError: (err) {
        print('❌ Deep link error: $err');
      });

      // Check if app was opened with a deep link
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('❌ Failed to initialize deep link listener: $e');
    }
  }

  // Handle OAuth callback deep link
  Future<void> _handleDeepLink(Uri uri) async {
    print('========================================');
    print('🔗 DEEP LINK RECEIVED');
    print('URI: $uri');
    print('Scheme: ${uri.scheme}');
    print('Host: ${uri.host}');
    print('Path: ${uri.path}');
    print('========================================');

    // Check if this is an OAuth2 callback
    if (uri.scheme == 'brightwin' && uri.host == 'oauth2' && uri.path == '/redirect') {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Process the OAuth callback
        final jwtResponse = await _authRepository.authenticateWithLinkedIn(uri);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${jwtResponse.firstName}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } catch (e) {
        print('❌ LinkedIn authentication error: $e');

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'LinkedIn sign-in failed. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LinkedIn sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Handle LinkedIn Sign-In
  Future<void> _handleLinkedInSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('========================================');
      print('🔗 LINKEDIN SIGN-IN INITIATED');
      print('========================================');

      // Get the LinkedIn authorization URL from repository
      final authUrl = _authRepository.getLinkedInAuthUrl();

      print('🌐 Opening LinkedIn authorization URL...');

      // Launch the URL in browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        print('✅ Browser launched successfully');

        // Show a message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening LinkedIn... Please authorize the app'),
              backgroundColor: Color(0xFF0A66C2),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Could not launch LinkedIn authorization URL');
      }

      // Reset loading state after a delay
      // The actual auth will happen when deep link is received
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ LinkedIn sign-in error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to open LinkedIn. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open LinkedIn: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
    // TODO: Load from secure storage
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      // TODO: Save to secure storage
    } else {
      // TODO: Clear saved credentials
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _deepLinkSubscription?.cancel();
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

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Environment Toggle Button
                Align(
                  alignment: Alignment.topRight,
                  child: OutlinedButton.icon(
                    onPressed: _toggleEnvironment,
                    icon: Icon(
                      _environmentService.isDevelopment
                          ? Icons.developer_mode
                          : Icons.cloud_done,
                      size: 16,
                    ),
                    label: Text(
                      _currentEnvironment,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _environmentService.isDevelopment
                          ? Colors.orange
                          : Colors.green,
                      side: BorderSide(
                        color: _environmentService.isDevelopment
                            ? Colors.orange
                            : Colors.green,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 24),
                // LinkedIn Sign-In - Primary Option
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A66C2), // LinkedIn brand color
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A66C2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleLinkedInSignIn,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.work,
                                  color: Color(0xFF0A66C2),
                                  size: 20,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Text(
                              _isLoading ? 'Opening LinkedIn...' : 'Continue with LinkedIn',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 24),
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
                    GestureDetector(
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
                    const Spacer(),
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
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In',
                  onPressed: _handleSignIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In with LinkedIn',
                  onPressed: _isLoading ? null : _handleLinkedInSignIn,
                  isOutlined: true,
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                // Fast login for development
                CustomButton(
                  text: 'Fast Login (Dev)',
                  onPressed: () {
                    _emailController.text = 'rami.khawaly@gigaspaces.com';
                    _passwordController.text = 'r218117r';
                    _handleSignIn();
                  },
                  isOutlined: true,
                  icon: Icons.flash_on,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.signUp);
                      },
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
