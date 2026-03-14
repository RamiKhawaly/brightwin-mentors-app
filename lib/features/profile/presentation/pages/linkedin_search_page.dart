import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/linkedin_import_service.dart';

/// Starts the LinkedIn background import and immediately returns the user
/// to the previous screen. A floating banner (LinkedInImportBanner) will
/// show the progress across the whole app and let the user resume the
/// approval flow when the import completes.
class LinkedInSearchPage extends StatefulWidget {
  const LinkedInSearchPage({super.key});

  @override
  State<LinkedInSearchPage> createState() => _LinkedInSearchPageState();
}

class _LinkedInSearchPageState extends State<LinkedInSearchPage> {
  static const _storage = FlutterSecureStorage();
  bool _started = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _kickOff();
  }

  Future<void> _kickOff() async {
    // Extract display name from JWT (informational only)
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
          switch (payload.length % 4) {
            case 2:
              payload += '==';
              break;
            case 3:
              payload += '=';
              break;
          }
          final claims = json.decode(utf8.decode(base64.decode(payload)))
              as Map<String, dynamic>;
          final first = claims['firstName'] as String? ?? '';
          final last = claims['lastName'] as String? ?? '';
          final name = '$first $last'.trim();
          if (name.isNotEmpty && mounted) {
            setState(() => _userName = name);
          }
        }
      }
    } catch (_) {}

    // Start the background import (no-op if already running)
    LinkedInImportService.instance.start();

    if (mounted) setState(() => _started = true);

    // Brief pause so the user sees the confirmation, then pop back
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from LinkedIn'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pulsing LinkedIn icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.05),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link,
                  size: 40,
                  color: Color(0xFF0A66C2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _started ? 'Import started!' : 'Starting import…',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_userName != null)
              Text(
                'Searching LinkedIn for $_userName',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              'This runs in the background — you can keep going.\n'
              'A notification at the bottom of the screen will let you know when it\'s ready.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Animated dots
            if (!_started)
              const _LoadingDots()
            else
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0A66C2),
                size: 36,
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final scale = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.4, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A66C2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
