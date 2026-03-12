import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/environment_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/repositories/auth_repository_impl.dart';

class GoogleLoginPage extends StatefulWidget {
  const GoogleLoginPage({super.key});

  @override
  State<GoogleLoginPage> createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends State<GoogleLoginPage> {
  late AuthRepositoryImpl _authRepository;
  final _environmentService = EnvironmentService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndStartAuth();
  }

  Future<void> _initializeAndStartAuth() async {
    try {
      // Initialize environment service
      await _environmentService.initialize();

      final storage = const FlutterSecureStorage();
      final dioClient = DioClient(storage);
      _authRepository = AuthRepositoryImpl(dioClient, storage, _environmentService);

      // Get Google OAuth URL
      final googleAuthUrl = _authRepository.getGoogleAuthUrl();

      print('🌐 Starting Google OAuth in external browser');
      print('Auth URL: $googleAuthUrl');

      // Launch OAuth flow in external browser
      // This complies with Google's "Use secure browsers" policy
      final uri = Uri.parse(googleAuthUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!mounted) return;

        // Show instructions to user
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Could not launch browser for authentication');
      }
    } catch (e) {
      print('❌ Error during Google OAuth: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to start authentication: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ),
      body: Center(
        child: _errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.signIn),
                    child: const Text('Back to Sign In'),
                  ),
                ],
              )
            : _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Opening browser...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.web,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Complete sign in in your browser',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'After signing in with Google in your browser, you will be automatically redirected back to the app.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _initializeAndStartAuth();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.signIn),
                          child: const Text('Cancel and go back'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
