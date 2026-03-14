import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/router_config.dart';
import '../../data/models/user_profile_response_model.dart';
import '../../data/models/education_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'profile_edit_page.dart';
import 'complete_profile_from_cv_page.dart';
import 'linkedin_search_page.dart';
import '../../../../core/services/linkedin_import_service.dart';

/// LinkedIn-style comprehensive profile view page - MAIN PROFILE PAGE
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepositoryImpl _profileRepository;
  UserProfileResponseModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _profileRepository = ProfileRepositoryImpl(dioClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditPage(),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  void _navigateToLinkedInScraper() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LinkedInSearchPage(),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  void _navigateToCompleteFromCV() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompleteProfileFromCVPage(),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: Text('Failed to load profile')),
      );
    }

    final profile = _profile!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.mentorSettings),
            tooltip: 'Mentor Settings',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            _buildProfileHeader(context),

            const SizedBox(height: 8),

            // About Section
            if (profile.bio != null && profile.bio!.isNotEmpty)
              _buildAboutSection(context),

            // Mentor Seniority Section
            if (profile.mentorSeniority != null || (profile.canMentorLevels != null && profile.canMentorLevels!.isNotEmpty))
              _buildMentorSenioritySection(context),

            // Companies Section - Show all companies the mentor worked for
            if (profile.companyHistory != null && profile.companyHistory!.isNotEmpty)
              _buildCompaniesSection(context),

            // Complete from CV CTA (if incomplete profile and no import running)
            if (profile.companyHistory == null || profile.companyHistory!.isEmpty ||
                profile.education == null || profile.education!.isEmpty)
              ListenableBuilder(
                listenable: LinkedInImportService.instance,
                builder: (_, __) =>
                    LinkedInImportService.instance.status == LinkedInImportStatus.running
                        ? const SizedBox.shrink()
                        : _buildCompleteFromCVBanner(),
              ),

            // Company History Section (using new companyHistory field)
            if (profile.companyHistory != null && profile.companyHistory!.isNotEmpty)
              _buildCompanyHistorySection(context),

            // Education Section
            if (profile.education != null && profile.education!.isNotEmpty)
              _buildEducationSection(context),

            // Skills Section
            if (profile.skills != null && profile.skills!.isNotEmpty)
              _buildSkillsSection(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover photo area (placeholder)
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Profile picture and basic info
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                // Profile picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profile!.imageUrl != null
                        ? NetworkImage(_profile!.imageUrl!)
                        : null,
                    child: _profile!.imageUrl == null
                        ? Text(
                            _profile!.firstName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 48),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  _profile!.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Current job title and company
                if (_profile!.currentJobTitle != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _profile!.currentCompany != null
                          ? '${_profile!.currentJobTitle} at ${_profile!.currentCompany!.name}'
                          : _profile!.currentJobTitle!,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 8),

                // Location
                if (_profile!.location != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _profile!.location!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Rating Display (compact) - Always show
                InkWell(
                  onTap: (_profile!.ratingStats != null &&
                          _profile!.ratingStats!.totalRatings != null &&
                          _profile!.ratingStats!.totalRatings! > 0)
                      ? () => _showMentorRatingBreakdown()
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 18),
                        const SizedBox(width: 4),
                        Text(
                          (_profile!.ratingStats?.averageRating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${_profile!.ratingStats?.totalRatings ?? 0})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_profile!.ratingStats != null &&
                            _profile!.ratingStats!.totalRatings != null &&
                            _profile!.ratingStats!.totalRatings! > 0) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Social links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_profile!.linkedInUrl != null)
                      _buildSocialButton(
                        context,
                        Icons.link,
                        'LinkedIn',
                        _profile!.linkedInUrl!,
                      ),
                    if (_profile!.githubUrl != null) ...[
                      const SizedBox(width: 12),
                      _buildSocialButton(
                        context,
                        Icons.code,
                        'GitHub',
                        _profile!.githubUrl!,
                      ),
                    ],
                    if (_profile!.portfolioUrl != null) ...[
                      const SizedBox(width: 12),
                      _buildSocialButton(
                        context,
                        Icons.web,
                        'Portfolio',
                        _profile!.portfolioUrl!,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    IconData icon,
    String label,
    String url,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildMentorSenioritySection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentor Level',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_profile!.mentorSeniority != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile!.mentorSeniority!.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (_profile!.canMentorLevels != null && _profile!.canMentorLevels!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Can Mentor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.canMentorLevels!.map((level) {
                return Chip(
                  label: Text(level.displayName),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showMentorRatingBreakdown() async {
    if (_profile == null || _profile!.ratingStats == null || _profile!.ratingStats!.totalRatings == null || _profile!.ratingStats!.totalRatings! == 0) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final dioClient = DioClient(const FlutterSecureStorage());
      final response = await dioClient.dio.get('/api/ratings/mentor/stats/${_profile!.id}');

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      final detailedStats = response.data;

      // Show rating breakdown dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.insights, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Expanded(child: Text('Rating Breakdown')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              detailedStats['averageOverallRating']?.toStringAsFixed(1) ?? '0.0',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (detailedStats['averageOverallRating'] ?? 0).round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber[700],
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Overall Rating',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              '${detailedStats['totalRatings'] ?? 0}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Reviews',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recommendation stats
                  if (detailedStats['recommendationStats'] != null) ...[
                    Text(
                      'Recommendations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up, color: Colors.green[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${detailedStats['recommendationStats']['wouldRecommendCount'] ?? 0} of ${detailedStats['totalRatings'] ?? 0} would recommend',
                              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${((detailedStats['recommendationStats']['recommendationPercentage'] ?? 0.0)).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rating dimensions
                  Text(
                    'Rating Dimensions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildDimensionBreakdown(
                    context,
                    'Expertise',
                    detailedStats['averageExpertise']?.toDouble() ?? 0.0,
                    Icons.school,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  _buildDimensionBreakdown(
                    context,
                    'Communication',
                    detailedStats['averageCommunication']?.toDouble() ?? 0.0,
                    Icons.forum,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),

                  _buildDimensionBreakdown(
                    context,
                    'Helpfulness',
                    detailedStats['averageHelpfulness']?.toDouble() ?? 0.0,
                    Icons.favorite,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),

                  _buildDimensionBreakdown(
                    context,
                    'Professionalism',
                    detailedStats['averageProfessionalism']?.toDouble() ?? 0.0,
                    Icons.business_center,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),

                  _buildDimensionBreakdown(
                    context,
                    'Responsiveness',
                    detailedStats['averageResponsiveness']?.toDouble() ?? 0.0,
                    Icons.speed,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load rating breakdown: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDimensionBreakdown(
    BuildContext context,
    String dimension,
    double average,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                dimension,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: average / 5.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesSection(BuildContext context) {
    // Get unique companies (avoid duplicates from multiple positions at same company)
    final uniqueCompanies = <String, CompanyExperienceInfo>{};
    for (var exp in _profile!.companyHistory!) {
      if (!uniqueCompanies.containsKey(exp.companyName)) {
        uniqueCompanies[exp.companyName] = exp;
      }
    }
    final companies = uniqueCompanies.values.toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Companies',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${companies.length} ${companies.length == 1 ? 'company' : 'companies'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Company logos in a grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: companies.map((company) => _buildCompanyLogoCard(context, company)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoCard(BuildContext context, CompanyExperienceInfo company) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              image: company.companyLogo != null
                  ? DecorationImage(
                      image: NetworkImage(company.companyLogo!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: company.companyLogo == null
                ? Center(
                    child: Text(
                      company.companyName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  company.companyName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (company.companyVerified == true) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.verified,
                  size: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ],
          ),
          if (company.industry != null) ...[
            const SizedBox(height: 2),
            Text(
              company.industry!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _profile!.bio!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteFromCVBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile with AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Import from LinkedIn or upload your CV to get started',
                      style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Primary: LinkedIn (client-side scraper)
          ElevatedButton.icon(
            onPressed: _navigateToLinkedInScraper,
            icon: const Icon(Icons.link),
            label: const Text('Import from LinkedIn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Secondary: upload CV
          OutlinedButton.icon(
            onPressed: _navigateToCompleteFromCV,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload CV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyHistorySection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._profile!.companyHistory!.map((exp) => _buildCompanyExperienceCard(context, exp)),
        ],
      ),
    );
  }

  Widget _buildCompanyExperienceCard(BuildContext context, CompanyExperienceInfo experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              image: experience.companyLogo != null
                  ? DecorationImage(
                      image: NetworkImage(experience.companyLogo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: experience.companyLogo == null
                ? const Icon(Icons.business, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position
                Text(
                  experience.position,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                // Company with verified badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        experience.companyName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (experience.companyVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Period and duration
                Text(
                  '${experience.periodString} · ${experience.duration}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                // Location and employment type
                Row(
                  children: [
                    if (experience.location != null) ...[
                      Text(
                        experience.location!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (experience.location != null && experience.employmentType != null)
                      Text(
                        ' · ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    if (experience.employmentType != null)
                      Text(
                        experience.employmentType!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                // Company description (if available)
                if (experience.companyDescription != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    experience.companyDescription!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Industry tag
                if (experience.industry != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      experience.industry!,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Education',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Add education
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._profile!.education!.map((edu) => _buildEducationCard(context, edu)),
        ],
      ),
    );
  }

  Widget _buildEducationCard(BuildContext context, EducationModel education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School logo placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.school, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institution
                Text(
                  education.institution,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                // Degree and field
                Text(
                  education.degreeWithField,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                // Period
                Text(
                  education.periodString,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (education.grade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Grade: ${education.grade}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                if (education.gpa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPA: ${education.gpa}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                if (education.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    education.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _profile!.skills!.map((userSkill) {
              return _buildSkillChip(context, userSkill);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, SkillInfo skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skill.skillName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (skill.category != null) ...[
            const SizedBox(height: 4),
            Text(
              skill.category!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
          if (skill.proficiencyLevel != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < skill.proficiencyLevel! ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber[700],
                  );
                }),
              ],
            ),
          ],
          if (skill.yearsOfExperience != null) ...[
            const SizedBox(height: 2),
            Text(
              '${skill.yearsOfExperience} ${skill.yearsOfExperience == 1 ? 'year' : 'years'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
