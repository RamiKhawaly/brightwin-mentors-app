import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/router_config.dart';

/// Global navigation service that can be used outside of widget context
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Navigate to login screen and clear navigation stack
  void navigateToLogin() {
    final context = AppRouterConfig.router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      context.go(AppRoutes.signIn);
    }
  }

  /// Show a snackbar message
  void showSnackBar(String message, {Color? backgroundColor}) {
    final context = AppRouterConfig.router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
