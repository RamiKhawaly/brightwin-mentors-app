import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'profile_preview_approval_page.dart';

enum _Phase { input, webview, processing }

/// Client-side LinkedIn profile scraper.
///
/// Flow:
///  1. User enters LinkedIn username / URL → tap "Open & Scan"
///  2. WebView loads the public profile so the user can verify (and log in if needed)
///  3. When ready, user taps "Scan Profile" → HTML is extracted via JS
///  4. HTML is POSTed to /api/linkedin/scrape-html for AI formatting
///  5. Navigate to ProfilePreviewApprovalPage for review
class LinkedInScraperPage extends StatefulWidget {
  const LinkedInScraperPage({super.key});

  @override
  State<LinkedInScraperPage> createState() => _LinkedInScraperPageState();
}

class _LinkedInScraperPageState extends State<LinkedInScraperPage> {
  late final ProfileRepositoryImpl _profileRepository;
  final _urlController = TextEditingController();

  _Phase _phase = _Phase.input;
  late WebViewController _webController;
  bool _pageLoaded = false;
  bool _isExtracting = false;
  String _statusMessage = '';
  bool _showUsernameGuide = false;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepositoryImpl(
      DioClient(const FlutterSecureStorage()),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // ───────────────────────── helpers ──────────────────────────

  String? _normaliseLinkedInUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final urlPattern = RegExp(
      r'(?:https?://)?(?:www\.)?linkedin\.com/in/([^/?#\s]+)',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(input);
    if (match != null) {
      final username = match.group(1)!.replaceAll(RegExp(r'/+$'), '');
      return 'https://www.linkedin.com/in/$username/';
    }

    final usernamePattern = RegExp(r'^[A-Za-z0-9\-]+$');
    if (usernamePattern.hasMatch(input)) {
      return 'https://www.linkedin.com/in/$input/';
    }

    return null;
  }

  // ───────────────────────── actions ──────────────────────────

  void _openWebView() {
    final url = _normaliseLinkedInUrl(_urlController.text);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not recognise that LinkedIn input. '
            'Try entering just your username, e.g. john-doe',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted && !_pageLoaded) {
              setState(() => _pageLoaded = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() {
      _phase = _Phase.webview;
      _pageLoaded = false;
    });
  }

  Future<void> _extractAndSend() async {
    if (_isExtracting) return;
    setState(() {
      _isExtracting = true;
      _phase = _Phase.processing;
      _statusMessage = 'Extracting profile HTML…';
    });

    try {
      // Pull the full rendered HTML from the WebView
      final jsResult = await _webController.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );

      String html = jsResult.toString();
      // The JS bridge returns a JSON-encoded string — decode it
      try {
        final decoded = json.decode(html);
        if (decoded is String) html = decoded;
      } catch (_) {
        // already a plain string, use as-is
      }

      if (!mounted) return;
      setState(() => _statusMessage = 'Sending to server for AI analysis…');

      final extractedProfile =
          await _profileRepository.importProfileFromLinkedInHtml(html);

      if (!mounted) return;

      final approved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfilePreviewApprovalPage(profilePreview: extractedProfile),
        ),
      );

      if (approved == true && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        setState(() {
          _phase = _Phase.input;
          _pageLoaded = false;
          _isExtracting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.input;
        _pageLoaded = false;
        _isExtracting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ───────────────────────── build ──────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from LinkedIn'),
        leading: _phase == _Phase.webview
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _phase = _Phase.input;
                  _pageLoaded = false;
                }),
              )
            : null,
      ),
      body: switch (_phase) {
        _Phase.input => _buildInputPhase(),
        _Phase.webview => _buildWebViewPhase(),
        _Phase.processing => _buildProcessingPhase(),
      },
    );
  }

  // ─── Phase 1: URL input ───────────────────────────────────

  Widget _buildInputPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.link, size: 80, color: Color(0xFF0A66C2)),
          const SizedBox(height: 24),
          Text(
            'Import from LinkedIn',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your LinkedIn username or profile URL. '
            'We\'ll open your public profile and extract your information automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureItem(
            Icons.person_outline,
            'Personal Info',
            'Name, headline, and contact details',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.work_outline,
            'Work Experience',
            'Full work history from your public profile',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.school_outlined,
            'Education',
            'Degrees, institutions, and qualifications',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.star_outline,
            'Skills',
            'Listed skills and expertise',
          ),
          const SizedBox(height: 40),
          CustomTextField(
            label: 'LinkedIn Username or URL',
            controller: _urlController,
            prefixIcon: const Icon(Icons.link),
            hint: 'john-doe  or  linkedin.com/in/john-doe',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          Text(
            'Accepted: john-doe · linkedin.com/in/john-doe · full URL',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildFindUsernameGuide(),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Open & Scan LinkedIn Profile',
            onPressed: _openWebView,
            icon: Icons.open_in_new,
          ),
        ],
      ),
    );
  }

  // ─── Phase 2: WebView ────────────────────────────────────

  Widget _buildWebViewPhase() {
    return Stack(
      children: [
        WebViewWidget(controller: _webController),

        // Dim + spinner while page is still loading
        if (!_pageLoaded)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading LinkedIn profile…',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

        // Bottom action bar once the page is loaded
        if (_pageLoaded)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profile loaded — verify and tap Scan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _extractAndSend,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A66C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Phase 3: Processing ─────────────────────────────────

  Widget _buildProcessingPhase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFindUsernameGuide() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showUsernameGuide = !_showUsernameGuide),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How to find your LinkedIn username?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Icon(
                    _showUsernameGuide
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (_showUsernameGuide) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(1, 'Open the LinkedIn app',
                      'Launch LinkedIn on your phone'),
                  _buildStep(2, 'Go to your profile',
                      'Tap your profile picture → "View Profile"'),
                  _buildStep(3, 'Open "Contact info"',
                      'Scroll down and tap "Contact info" below your headline'),
                  _buildStep(
                    4,
                    'Find your profile URL',
                    'Under "Your Profile" you\'ll see linkedin.com/in/john-doe — the part after /in/ is your username',
                    isLast: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18,
                            color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Example: if your URL is linkedin.com/in/john-doe, just enter john-doe',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 36, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
