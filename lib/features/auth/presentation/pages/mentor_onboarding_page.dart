import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/network/dio_client.dart';
import '../../../settings/data/models/mentor_settings_request.dart';
import '../../../profile/presentation/pages/complete_profile_from_linkedin_page.dart';
import '../../../profile/presentation/pages/complete_profile_from_cv_page.dart';
import 'mentor_preferences_onboarding_page.dart';
import 'onboarding_profile_builder_page.dart';

class MentorOnboardingPage extends StatefulWidget {
  const MentorOnboardingPage({super.key});

  @override
  State<MentorOnboardingPage> createState() => _MentorOnboardingPageState();
}

class _MentorOnboardingPageState extends State<MentorOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  bool _isSaving = false;

  // Total pages: intro1, intro2, profile builder, preferences
  static const int _totalPages = 4;

  // Mentor preferences state
  final Map<String, bool> _selectedSeniorityLevels = {
    'INTERN': false,
    'JUNIOR': false,
    'MID_LEVEL': false,
    'SENIOR': false,
    'LEAD': false,
    'PRINCIPAL': false,
    'ARCHITECT': false,
  };

  final Map<String, bool> _selectedLanguages = {
    'English': false,
    'Hebrew': false,
    'Arabic': false,
  };

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(_storage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final hasLanguages = _selectedLanguages.values.any((v) => v);
    final hasSeniorityLevels = _selectedSeniorityLevels.values.any((v) => v);

    if (!hasLanguages || !hasSeniorityLevels) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !hasLanguages && !hasSeniorityLevels
                ? 'Please select at least one language and one seniority level'
                : !hasLanguages
                    ? 'Please select at least one language'
                    : 'Please select at least one seniority level',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final selectedLanguagesList = _selectedLanguages.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final selectedSeniorityLevelsList = _selectedSeniorityLevels.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final mentorSeniority = selectedSeniorityLevelsList.isNotEmpty
          ? selectedSeniorityLevelsList.last
          : 'MID_LEVEL';

      final request = MentorSettingsRequest(
        mentorSeniority: mentorSeniority,
        canMentorLevels: selectedSeniorityLevelsList,
        availableForSessions: true,
        interviewLanguages: selectedLanguagesList,
      );

      print('💾 Saving mentor preferences during onboarding...');
      print('Request body: ${request.toJson()}');

      await _dioClient.dio.put(
        '/api/profile/mentor-settings',
        data: request.toJson(),
      );

      print('✅ Mentor preferences saved successfully');

      await _storage.write(key: 'onboarding_completed', value: 'true');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      context.go(AppRoutes.home);
    } catch (e) {
      print('❌ Error saving mentor preferences: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onPreferencesChanged(
    Map<String, bool> seniorityLevels,
    Map<String, bool> languages,
  ) {
    setState(() {
      _selectedSeniorityLevels.clear();
      _selectedSeniorityLevels.addAll(seniorityLevels);
      _selectedLanguages.clear();
      _selectedLanguages.addAll(languages);
    });
  }

  void _advanceToPreferences() {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openLinkedInImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CompleteProfileFromLinkedInPage(),
      ),
    );

    if (!mounted) return;

    // Whether profile was saved or skipped, advance to preferences
    _advanceToPreferences();

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile imported from LinkedIn!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCVImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CompleteProfileFromCVPage(),
      ),
    );

    if (!mounted) return;

    _advanceToPreferences();

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile built from CV!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildJobReferralPage(context),
                  _buildMentorshipPage(context),
                  OnboardingProfileBuilderPage(
                    onLinkedInTap: _openLinkedInImport,
                    onCVTap: _openCVImport,
                    onManualTap: _advanceToPreferences,
                  ),
                  MentorPreferencesOnboardingPage(
                    selectedSeniorityLevels: _selectedSeniorityLevels,
                    selectedLanguages: _selectedLanguages,
                    onPreferencesChanged: _onPreferencesChanged,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Hide the Next button on the profile builder page (index 2)
                  // since the option cards handle navigation directly
                  if (_currentPage != 2) ...[
                    CustomButton(
                      text: _currentPage == 3 ? 'Get Started' : 'Next',
                      onPressed: _isSaving
                          ? () {}
                          : () {
                              if (_currentPage == 3) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                      icon: _currentPage == 3
                          ? Icons.rocket_launch
                          : Icons.arrow_forward,
                      isLoading: _isSaving,
                    ),
                    if (_currentPage < 3) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            3,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ] else ...[
                    // On profile builder page, show a subtle skip option
                    TextButton(
                      onPressed: _advanceToPreferences,
                      child: Text(
                        'Skip profile setup for now',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobReferralPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Post Internal Jobs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Friend Brings Friend Program',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildFeatureRow(
                  context,
                  Icons.business,
                  'Post jobs from your company',
                  'Share internal job openings with qualified candidates',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  context,
                  Icons.people,
                  'Candidates apply to your jobs',
                  'Review applications and CVs from interested candidates',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  context,
                  Icons.forward_to_inbox,
                  'Forward as referrals',
                  'Refer qualified candidates to HR and earn referral bonuses',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Help candidates get hired and earn rewards!',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorshipPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Mentor & Guide',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Help Candidates Succeed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildFeatureRow(
                  context,
                  Icons.phone,
                  'Phone calls & guidance',
                  'Provide career advice and answer candidate questions',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  context,
                  Icons.mic,
                  'Mock interviews',
                  'Conduct practice interviews to prepare candidates',
                ),
                const SizedBox(height: 20),
                _buildFeatureRow(
                  context,
                  Icons.feedback,
                  'Feedback & tips',
                  'Give constructive feedback to help candidates improve',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Earn badges for your mentorship activities!',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
