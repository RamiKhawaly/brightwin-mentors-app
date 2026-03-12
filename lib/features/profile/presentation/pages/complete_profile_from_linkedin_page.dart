import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'profile_preview_approval_page.dart';

/// Page for importing profile data from LinkedIn via POST /api/linkedin/preview
class CompleteProfileFromLinkedInPage extends StatefulWidget {
  const CompleteProfileFromLinkedInPage({super.key});

  @override
  State<CompleteProfileFromLinkedInPage> createState() =>
      _CompleteProfileFromLinkedInPageState();
}

class _CompleteProfileFromLinkedInPageState
    extends State<CompleteProfileFromLinkedInPage> {
  late final ProfileRepositoryImpl _profileRepository;
  final _linkedInUrlController = TextEditingController();
  bool _isProcessing = false;
  bool _showUsernameGuide = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _profileRepository = ProfileRepositoryImpl(dioClient);
  }

  @override
  void dispose() {
    _linkedInUrlController.dispose();
    super.dispose();
  }

  /// Normalises any LinkedIn input to https://www.linkedin.com/in/<username>/
  ///
  /// Accepts:
  ///   ramix
  ///   linkedin.com/in/ramix
  ///   www.linkedin.com/in/ramix
  ///   http://linkedin.com/in/ramix
  ///   https://www.linkedin.com/in/ramix/
  String? _normaliseLinkedInUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    // If it already looks like a full or partial URL, extract the username
    final urlPattern = RegExp(
      r'(?:https?://)?(?:www\.)?linkedin\.com/in/([^/?#\s]+)',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(input);
    if (match != null) {
      final username = match.group(1)!.replaceAll(RegExp(r'/+$'), '');
      return 'https://www.linkedin.com/in/$username/';
    }

    // Otherwise treat the entire input as a plain username
    // Reject if it contains spaces or obviously invalid characters
    final usernamePattern = RegExp(r'^[A-Za-z0-9\-]+$');
    if (usernamePattern.hasMatch(input)) {
      return 'https://www.linkedin.com/in/$input/';
    }

    return null; // could not parse
  }

  Future<void> _importFromLinkedIn() async {
    final raw = _linkedInUrlController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your LinkedIn username or profile URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final url = _normaliseLinkedInUrl(raw);
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

    setState(() {
      _isProcessing = true;
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Reading your LinkedIn profile...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final extractedProfile =
          await _profileRepository.importProfileFromLinkedIn(url);

      if (!mounted) return;

      Navigator.pop(context); // close loading dialog

      setState(() {
        _isProcessing = false;
      });

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePreviewApprovalPage(
            profilePreview: extractedProfile,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // close loading dialog

      setState(() {
        _isProcessing = false;
      });

      final errorCode = e.response?.data is Map
          ? e.response?.data['errorCode'] as String?
          : null;

      final message = _linkedInErrorMessage(errorCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // close loading dialog

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing LinkedIn profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _linkedInErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'LINKEDIN_PROFILE_BLOCKED':
        return 'LinkedIn has temporarily blocked access to your profile (rate limit or bot detection). '
            'Please try again in a few minutes or use a different method to build your profile.';
      case 'LINKEDIN_PROFILE_UNREACHABLE':
        return 'Could not reach LinkedIn at this time (network timeout or server error). '
            'Please check your connection and try again.';
      default:
        return 'Failed to import your LinkedIn profile. Please try again or build your profile manually.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from LinkedIn'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.link,
                size: 80,
                color: const Color(0xFF0A66C2),
              ),
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
                'Enter your LinkedIn username or profile URL and we\'ll automatically import your professional information',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              _buildFeatureItem(
                Icons.person_outline,
                'Personal Info',
                'Import your name, headline, and contact details',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.work_outline,
                'Work Experience',
                'Bring in your full work history from LinkedIn',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.school_outlined,
                'Education',
                'Import your educational background and qualifications',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.star_outline,
                'Skills',
                'Automatically extract your listed skills and expertise',
              ),
              const SizedBox(height: 40),

              // URL / username input
              CustomTextField(
                label: 'LinkedIn Username or URL',
                controller: _linkedInUrlController,
                prefixIcon: const Icon(Icons.link),
                hint: 'john-doe  or  linkedin.com/in/john-doe',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Text(
                'Accepted: john-doe · linkedin.com/in/john-doe · full URL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // How to find username guide
              _buildFindUsernameGuide(),

              const SizedBox(height: 20),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0A66C2).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: const Color(0xFF0A66C2)),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A66C2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Enter your LinkedIn username or profile URL\n'
                      '2. We\'ll read and extract your profile data\n'
                      '3. Review and edit the imported information\n'
                      '4. Save to complete your profile',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Import Profile',
                onPressed: _isProcessing ? () {} : _importFromLinkedIn,
                isLoading: _isProcessing,
                icon: Icons.download,
              ),
            ],
          ),
        ),
      ),
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
          // Toggle header
          InkWell(
            onTap: () {
              setState(() {
                _showUsernameGuide = !_showUsernameGuide;
              });
            },
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

          // Steps (collapsible)
          if (_showUsernameGuide) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(
                    1,
                    'Open the LinkedIn app',
                    'Launch LinkedIn on your phone',
                  ),
                  _buildStep(
                    2,
                    'Go to your profile',
                    'Tap your profile picture in the top-left corner, then tap "View Profile"',
                  ),
                  _buildStep(
                    3,
                    'Open "Contact info"',
                    'Scroll down a little and tap "Contact info" below your headline',
                  ),
                  _buildStep(
                    4,
                    'Find your profile URL',
                    'Under "Your Profile" you\'ll see a link like linkedin.com/in/john-doe — the part after /in/ is your username',
                    isLast: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
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

  Widget _buildStep(int number, String title, String description, {bool isLast = false}) {
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
              Container(
                width: 2,
                height: 36,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
