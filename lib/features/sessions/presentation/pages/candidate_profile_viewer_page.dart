import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';

class CandidateProfileViewerPage extends StatefulWidget {
  final int candidateId;

  const CandidateProfileViewerPage({
    super.key,
    required this.candidateId,
  });

  @override
  State<CandidateProfileViewerPage> createState() =>
      _CandidateProfileViewerPageState();
}

class _CandidateProfileViewerPageState
    extends State<CandidateProfileViewerPage> {
  late final DioClient _dioClient;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _ratingStats;
  List<dynamic>? _cvList;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(const FlutterSecureStorage());
    _loadCandidateData();
  }

  Future<void> _loadCandidateData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load candidate profile (includes aggregated rating stats)
      // Using /api/profile/{userId} as per backend instructions
      final profileResponse = await _dioClient.dio.get('/api/profile/${widget.candidateId}');

      if (!mounted) return;

      setState(() {
        _profile = profileResponse.data;

        // Extract rating stats from profile
        // Profile includes: candidateAverageRating, candidateTotalRatings
        _ratingStats = {
          'totalRatings': _profile?['candidateTotalRatings'] ?? 0,
          'averageOverallRating': _profile?['candidateAverageRating'] ?? 0.0,
        };

        // CV list is included in the profile response if available
        _cvList = _profile?['cvs'] as List<dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCandidateData,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load candidate profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retry',
                onPressed: _loadCandidateData,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          _buildRatingStats(),
          const SizedBox(height: 16),
          _buildAboutSection(),
          const SizedBox(height: 16),
          _buildExperienceSection(),
          const SizedBox(height: 16),
          _buildEducationSection(),
          const SizedBox(height: 16),
          _buildSkillsSection(),
          const SizedBox(height: 16),
          _buildCVSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile!;
    final fullName =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    final currentJobTitle = profile['currentJobTitle'];
    final currentCompanyRaw = profile['currentCompany'];
    final currentCompany = currentCompanyRaw is Map ? currentCompanyRaw['name'] : currentCompanyRaw;
    final location = profile['location'];
    final yearsOfExperience = profile['yearsOfExperience'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: profile['imageUrl'] != null
                  ? NetworkImage(profile['imageUrl'])
                  : null,
              child: profile['imageUrl'] == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Current Position
            if (currentJobTitle != null)
              Text(
                currentCompany != null
                    ? '$currentJobTitle at $currentCompany'
                    : currentJobTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),

            // Location and Experience
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                if (location != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                if (yearsOfExperience != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$yearsOfExperience years experience',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile['linkedInUrl'] != null)
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () => _launchURL(profile['linkedInUrl']),
                    tooltip: 'LinkedIn',
                  ),
                if (profile['githubUrl'] != null)
                  IconButton(
                    icon: const Icon(Icons.code),
                    onPressed: () => _launchURL(profile['githubUrl']),
                    tooltip: 'GitHub',
                  ),
                if (profile['portfolioUrl'] != null)
                  IconButton(
                    icon: const Icon(Icons.web),
                    onPressed: () => _launchURL(profile['portfolioUrl']),
                    tooltip: 'Portfolio',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStats() {
    if (_ratingStats == null || _ratingStats!['totalRatings'] == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No ratings yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _ratingStats!;
    final avgRating = stats['averageOverallRating'] ?? stats['averageRating'] ?? 0.0;
    final totalRatings = stats['totalRatings'] ?? 0;

    return Card(
      child: InkWell(
        onTap: () => _showRatingBreakdownDialog(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidate Rating',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$totalRatings ${totalRatings == 1 ? 'review' : 'reviews'} from mentors',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view detailed breakdown',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.chevron_right, color: Colors.blue[700], size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final bio = _profile!['bio'];
    if (bio == null || bio.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Text(bio),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    final experiences = _profile!['experiences'] as List<dynamic>?;
    if (experiences == null || experiences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...experiences.take(3).map((exp) => _buildExperienceItem(exp)),
            if (experiences.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${experiences.length - 3} more',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp['position'] ?? 'Position',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(exp['company'] ?? 'Company'),
          if (exp['startDate'] != null)
            Text(
              '${exp['startDate']} - ${exp['endDate'] ?? 'Present'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    final education = _profile!['education'] as List<dynamic>?;
    if (education == null || education.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Education',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...education.take(3).map((edu) => _buildEducationItem(edu)),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(Map<String, dynamic> edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu['institution'] ?? 'Institution',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(edu['degree'] ?? 'Degree'),
          if (edu['fieldOfStudy'] != null)
            Text(
              edu['fieldOfStudy'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _profile!['skills'] as List<dynamic>?;
    if (skills == null || skills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                final skillName = skill is String ? skill : skill['name'];
                return Chip(
                  label: Text(skillName ?? ''),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCVSection() {
    if (_cvList == null || _cvList!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No CV uploaded',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CV / Resume',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._cvList!.map((cv) => _buildCVItem(cv)),
          ],
        ),
      ),
    );
  }

  Widget _buildCVItem(Map<String, dynamic> cv) {
    final fileName = cv['fileName'] ?? 'Resume';
    final versionName = cv['versionName'] ?? 'Version';
    final fileUrl = cv['fileUrl'];
    final isDefault = cv['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(fileName),
        subtitle: Text(versionName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              ),
            const SizedBox(width: 8),
            if (fileUrl != null)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadCV(fileUrl, fileName),
                tooltip: 'Download CV',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _downloadCV(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening CV...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Could not open CV';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open CV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRatingBreakdownDialog() async {
    if (_ratingStats == null || _ratingStats!['totalRatings'] == 0) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch detailed rating statistics
      final response = await _dioClient.dio.get(
        '/api/ratings/candidate/stats/${widget.candidateId}',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final detailedStats = response.data;
      _showRatingBreakdownDialogContent(detailedStats);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load rating details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRatingBreakdownDialogContent(Map<String, dynamic> stats) {
    final avgOverall = stats['averageOverallRating']?.toDouble() ?? 0.0;
    final totalRatings = stats['totalRatings'] ?? 0;
    final recommendCount = stats['recommendationCount'] ?? 0;
    final recommendPercentage = stats['recommendationPercentage']?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rating Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on $totalRatings ${totalRatings == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Overall Rating
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Rating',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            avgOverall.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const Text(
                            ' / 5.0',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dimension Ratings
                Text(
                  'Rating Dimensions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                _buildDimensionRating(
                  'Professionalism',
                  'Professional attitude and conduct',
                  stats['averageProfessionalism']?.toDouble() ?? 0.0,
                  Icons.business_center,
                  Colors.blue,
                ),
                const SizedBox(height: 12),

                _buildDimensionRating(
                  'Communication',
                  'Clarity and effectiveness',
                  stats['averageCommunication']?.toDouble() ?? 0.0,
                  Icons.chat_bubble_outline,
                  Colors.green,
                ),
                const SizedBox(height: 12),

                _buildDimensionRating(
                  'Preparedness',
                  'Level of preparation',
                  stats['averagePreparedness']?.toDouble() ?? 0.0,
                  Icons.checklist,
                  Colors.orange,
                ),
                const SizedBox(height: 12),

                _buildDimensionRating(
                  'Engagement',
                  'Active participation',
                  stats['averageEngagement']?.toDouble() ?? 0.0,
                  Icons.people,
                  Colors.purple,
                ),
                const SizedBox(height: 12),

                _buildDimensionRating(
                  'Commitment',
                  'Dedication and follow-through',
                  stats['averageCommitment']?.toDouble() ?? 0.0,
                  Icons.star_border,
                  Colors.red,
                ),
                const SizedBox(height: 24),

                // Recommendations
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_up, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Would Recommend',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$recommendCount out of $totalRatings mentors (${recommendPercentage.toStringAsFixed(0)}%)',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionRating(
    String title,
    String subtitle,
    double rating,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/5',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rating / 5.0,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
