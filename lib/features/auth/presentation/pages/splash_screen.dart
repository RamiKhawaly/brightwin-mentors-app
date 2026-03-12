import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Check if user is first-time and navigate accordingly
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user has visited before
      final hasVisited = await _storage.read(key: 'has_visited');

      // Check "Keep me logged in" preference
      final keepLoggedIn = await _storage.read(key: 'keep_logged_in');

      // Check if user is logged in
      final token = await _storage.read(key: AppConstants.accessTokenKey);

      // Check if onboarding is completed
      final onboardingCompleted = await _storage.read(key: 'onboarding_completed');

      // If "Keep me logged in" is disabled, clear the auth token
      if (keepLoggedIn == 'false' && token != null) {
        print('🔒 Keep logged in is disabled, clearing auth token');
        await _storage.delete(key: 'auth_token');
        // Continue to login screen
        context.go(AppRoutes.signIn);
        return;
      }

      if (token != null && token.isNotEmpty) {
        // User is logged in and wants to stay logged in
        print('✅ User is logged in, keep_logged_in=${keepLoggedIn ?? "true"}');
        if (onboardingCompleted == 'true') {
          // Onboarding completed, go to home
          context.go(AppRoutes.home);
        } else {
          // Need to complete onboarding first
          context.go(AppRoutes.mentorOnboarding);
        }
      } else if (hasVisited == null) {
        // First-time user, go directly to registration
        await _storage.write(key: 'has_visited', value: 'true');
        context.go(AppRoutes.signUp);
      } else {
        // Returning user, show login
        context.go(AppRoutes.signIn);
      }
    } catch (e) {
      print('Error checking first-time user: $e');
      // Default to login on error
      context.go(AppRoutes.signIn);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Brightwin Mentors',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Connect, Prepare, and Win',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
