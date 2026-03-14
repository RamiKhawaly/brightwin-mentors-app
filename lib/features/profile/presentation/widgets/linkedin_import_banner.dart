import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/linkedin_import_service.dart';
import '../../data/models/linkedin_person_response.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../pages/linkedin_profile_approval_page.dart';
import '../pages/linkedin_profile_select_page.dart';

/// Floating banner shown app-wide while a LinkedIn import is in progress.
///
/// • Running  → spinner + "Importing LinkedIn profile…"
/// • Done     → green chip "Profile ready · Tap to continue"
/// • Failed   → red chip "Import failed · Tap to retry"
///
/// Tapping when done navigates the user into the approval → job-selection flow.
/// The banner disappears once the user completes that flow (or dismisses on failure).
class LinkedInImportBanner extends StatefulWidget {
  const LinkedInImportBanner({super.key});

  @override
  State<LinkedInImportBanner> createState() => _LinkedInImportBannerState();
}

class _LinkedInImportBannerState extends State<LinkedInImportBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);

    LinkedInImportService.instance.addListener(_onServiceChanged);
    _syncAnimation();
  }

  @override
  void dispose() {
    LinkedInImportService.instance.removeListener(_onServiceChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (LinkedInImportService.instance.isActive) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  // ─── tap handler ─────────────────────────────────────────────────────────

  Future<void> _onTap() async {
    final service = LinkedInImportService.instance;

    if (service.status != LinkedInImportStatus.done) return;

    final results = service.profiles;
    if (results.isEmpty) {
      service.reset();
      return;
    }

    LinkedInPersonResponse? person;

    final nav = AppRouterConfig.navigatorKey.currentState;
    if (nav == null) return;

    if (results.length == 1) {
      person = results[0];
    } else {
      person = await nav.push<LinkedInPersonResponse>(
        MaterialPageRoute(
          builder: (_) => LinkedInProfileSelectPage(profiles: results),
        ),
      );
    }

    if (person == null) return;

    // ── Step 2: fetch full profile via by-URL scrape ──────────────────────
    final profileUrl = person.url;
    if (profileUrl != null && profileUrl.isNotEmpty) {
      // Show a non-dismissible loading dialog while the scrape runs
      showDialog<void>(
        context: nav.overlay!.context,
        barrierDismissible: false,
        builder: (_) => const _FetchingProfileDialog(),
      );

      try {
        final repo = ProfileRepositoryImpl(
          DioClient(const FlutterSecureStorage()),
        );
        final fullProfiles = await repo.searchLinkedInByUrl(profileUrl);
        nav.pop(); // close loading dialog
        if (fullProfiles.isNotEmpty) {
          person = fullProfiles.first;
        }
      } catch (_) {
        nav.pop(); // close loading dialog — proceed with partial by-name data
      }
    }

    final done = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => LinkedInProfileApprovalPage(person: person!),
      ),
    );

    if (done == true) service.reset();
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom +
          16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: _BannerCard(
            status: LinkedInImportService.instance.status,
            errorMessage: LinkedInImportService.instance.error,
            onTap: _onTap,
            onDismiss: LinkedInImportService.instance.reset,
            onRetry: LinkedInImportService.instance.retry,
          ),
        ),
      ),
    );
  }
}

// ─── card ─────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final LinkedInImportStatus status;
  final String? errorMessage;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const _BannerCard({
    required this.status,
    required this.onTap,
    required this.onDismiss,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == LinkedInImportStatus.failed) {
      return _buildFailedCard();
    }

    final (bg, icon, iconColor, title, subtitle, showDismiss) =
        switch (status) {
      LinkedInImportStatus.running => (
          Colors.white,
          null,
          Colors.transparent,
          'Importing LinkedIn profile…',
          'This may take a few minutes',
          false,
        ),
      LinkedInImportStatus.done => (
          const Color(0xFFE8F5E9),
          Icons.check_circle_rounded,
          Colors.green,
          'Profile ready!',
          'Tap to review and continue',
          true,
        ),
      _ => (
          Colors.white,
          null,
          Colors.transparent,
          '',
          '',
          false,
        ),
    };

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: bg,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: status == LinkedInImportStatus.running ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (status == LinkedInImportStatus.running)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF0A66C2),
                  ),
                )
              else
                Icon(icon, color: iconColor, size: 28),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A66C2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.link, color: Colors.white, size: 16),
              ),

              if (showDismiss) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDismiss,
                  child:
                      Icon(Icons.close, size: 18, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedCard() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFFFEBEE),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'LinkedIn import failed',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A66C2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A66C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Retry',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── loading dialog shown while fetching full profile by URL ─────────────────

class _FetchingProfileDialog extends StatelessWidget {
  const _FetchingProfileDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0A66C2)),
              SizedBox(height: 20),
              Text(
                'Fetching full profile…',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'Retrieving your complete LinkedIn profile data.\nThis may take a moment.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
