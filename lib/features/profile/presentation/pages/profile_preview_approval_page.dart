import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/profile_preview_model.dart';
import '../../data/repositories/profile_repository_impl.dart';

/// Comprehensive profile preview and approval page
/// Allows editing all extracted sections before saving
class ProfilePreviewApprovalPage extends StatefulWidget {
  final ProfilePreviewModel profilePreview;

  const ProfilePreviewApprovalPage({
    super.key,
    required this.profilePreview,
  });

  @override
  State<ProfilePreviewApprovalPage> createState() => _ProfilePreviewApprovalPageState();
}

class _ProfilePreviewApprovalPageState extends State<ProfilePreviewApprovalPage> {
  late final ProfileRepositoryImpl _profileRepository;
  late ProfilePreviewModel _editableProfile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _profileRepository = ProfileRepositoryImpl(dioClient);
    _editableProfile = widget.profilePreview;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save basic profile info only if there are non-null fields
      final hasBasicInfo = _editableProfile.fullName != null ||
          _editableProfile.email != null ||
          _editableProfile.phone != null ||
          _editableProfile.location != null ||
          _editableProfile.linkedInUrl != null ||
          _editableProfile.githubUrl != null ||
          _editableProfile.portfolioUrl != null ||
          _editableProfile.professionalSummary != null ||
          _editableProfile.currentJobTitle != null ||
          _editableProfile.currentCompany != null ||
          _editableProfile.totalYearsOfExperience != null;

      if (hasBasicInfo) {
        await _profileRepository.saveExtractedProfile(_editableProfile);
      }

      // Save experiences — both company and position are required by the backend
      final validExperiences = _editableProfile.experiences
          .where((e) => e.company.isNotEmpty && e.position.isNotEmpty)
          .toList();
      if (validExperiences.isNotEmpty) {
        await _profileRepository.saveExperiences(validExperiences);
      }

      // Save education — both institution and degree are required by the backend
      final validEducation = _editableProfile.education
          .where((e) => e.institution.isNotEmpty && e.degree.isNotEmpty)
          .toList();
      if (validEducation.isNotEmpty) {
        await _profileRepository.saveEducation(validEducation);
      }

      // Save skills — skip entries that have no meaningful data
      final validSkills = _editableProfile.skills
          .where((s) => s.name.isNotEmpty)
          .toList();
      if (validSkills.isNotEmpty) {
        await _profileRepository.saveSkills(validSkills);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AI Quality Score Banner
            if (_editableProfile.aiQualityScore != null)
              _buildQualityScoreBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.preview, color: Theme.of(context).primaryColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review Extracted Data',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Review and edit your information before saving',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    _buildBasicInfoSection(),

                    const SizedBox(height: 16),

                    // Professional Summary Section
                    if (_editableProfile.professionalSummary != null)
                      _buildSectionCard(
                        'Professional Summary',
                        Icons.description,
                        [
                          Text(_editableProfile.professionalSummary!),
                          const SizedBox(height: 8),
                          if (_editableProfile.currentJobTitle != null)
                            Text('Current Role: ${_editableProfile.currentJobTitle}'),
                          if (_editableProfile.currentCompany != null)
                            Text('Company: ${_editableProfile.currentCompany}'),
                          if (_editableProfile.totalYearsOfExperience != null)
                            Text('Experience: ${_editableProfile.totalYearsOfExperience} years'),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Work Experience Section
                    _buildExperienceSection(),

                    const SizedBox(height: 16),

                    // Education Section
                    _buildEducationSection(),

                    const SizedBox(height: 16),

                    // Skills Section
                    _buildSkillsSection(),

                    const SizedBox(height: 16),

                    // Languages Section
                    if (_editableProfile.languages.isNotEmpty)
                      _buildLanguagesSection(),

                    const SizedBox(height: 16),

                    // AI Insights Section
                    if (_editableProfile.aiAnalysis != null ||
                        _editableProfile.aiStrengths != null ||
                        _editableProfile.aiRecommendations != null)
                      _buildAIInsightsSection(),

                    const SizedBox(height: 32),

                    // Action Buttons
                    CustomButton(
                      text: 'Save Profile',
                      onPressed: _isSaving ? () {} : _saveProfile,
                      isLoading: _isSaving,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityScoreBanner() {
    final score = _editableProfile.aiQualityScore!;
    final percentage = (score * 100).toInt();
    Color color;
    String message;

    if (percentage >= 80) {
      color = Colors.green;
      message = 'Excellent';
    } else if (percentage >= 60) {
      color = Colors.orange;
      message = 'Good';
    } else {
      color = Colors.red;
      message = 'Needs Improvement';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Quality: $message ($percentage%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    if (_editableProfile.experiences.isEmpty) {
      return _buildSectionCard(
        'Work Experience',
        Icons.work,
        [const Text('No work experience extracted')],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(Icons.work, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Work Experience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_editableProfile.experiences.length} positions',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._editableProfile.experiences.asMap().entries.map((entry) {
            final exp = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.position,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(exp.company),
                  if (exp.location != null) Text(exp.location!),
                  Text(
                    '${_formatDate(exp.startDate)} - ${exp.currentlyWorking ? "Present" : _formatDate(exp.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (exp.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      exp.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (exp.achievements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Key Achievements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...exp.achievements.map((achievement) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  achievement,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (exp.technologies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Technologies:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exp.technologies
                          .map((tech) => Chip(
                                label: Text(tech, style: const TextStyle(fontSize: 11)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              ))
                          .toList(),
                    ),
                  ],
                  if (entry.key < _editableProfile.experiences.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Divider(color: Colors.grey[300]),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    if (_editableProfile.education.isEmpty) {
      return _buildSectionCard(
        'Education',
        Icons.school,
        [const Text('No education records extracted')],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(Icons.school, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Education',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_editableProfile.education.length} degrees',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._editableProfile.education.asMap().entries.map((entry) {
            final edu = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.institution,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('${edu.degree}${edu.fieldOfStudy != null ? " in ${edu.fieldOfStudy}" : ""}'),
                  if (edu.location != null) Text(edu.location!),
                  Text(
                    '${_formatDate(edu.startDate)} - ${edu.currentlyStudying ? "Present" : _formatDate(edu.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (edu.gpa != null || edu.grade != null) ...[
                    const SizedBox(height: 4),
                    if (edu.gpa != null) Text('GPA: ${edu.gpa}'),
                    if (edu.grade != null) Text('Grade: ${edu.grade}'),
                  ],
                  if (entry.key < _editableProfile.education.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Divider(color: Colors.grey[300]),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    if (_editableProfile.skills.isEmpty) {
      return _buildSectionCard(
        'Skills',
        Icons.star,
        [const Text('No skills extracted')],
      );
    }

    // Group skills by category
    final Map<String, List<SkillPreviewModel>> skillsByCategory = {};
    for (final skill in _editableProfile.skills) {
      final category = skill.category ?? 'Other';
      skillsByCategory.putIfAbsent(category, () => []).add(skill);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_editableProfile.skills.length} skills',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...skillsByCategory.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((skill) {
                      return Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(skill.name),
                            if (skill.level != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${skill.level!.displayName})',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(Icons.person, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Full Name', _editableProfile.fullName),
          _buildInfoRow('Email', _editableProfile.email),
          _buildInfoRow('Phone', _editableProfile.phone),
          _buildInfoRow('Location', _editableProfile.location),

          // Social Links
          if (_editableProfile.linkedInUrl != null ||
              _editableProfile.githubUrl != null ||
              _editableProfile.portfolioUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Social Links',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            if (_editableProfile.linkedInUrl != null)
              _buildLinkRow('LinkedIn', _editableProfile.linkedInUrl!, Icons.link),
            if (_editableProfile.githubUrl != null)
              _buildLinkRow('GitHub', _editableProfile.githubUrl!, Icons.code),
            if (_editableProfile.portfolioUrl != null)
              _buildLinkRow('Portfolio', _editableProfile.portfolioUrl!, Icons.web),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not extracted',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value != null ? Colors.black : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            children: [
              Icon(Icons.language, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Languages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_editableProfile.languages.length} languages',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _editableProfile.languages.map((language) {
              return Chip(
                label: Text(language),
                avatar: const Icon(Icons.check_circle, size: 16),
                backgroundColor: Colors.blue[50],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple[700]),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // General AI Analysis
          if (_editableProfile.aiAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Overall Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_editableProfile.aiAnalysis!),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_editableProfile.aiStrengths != null) ...[
            _buildInsightItem('Strengths', _editableProfile.aiStrengths!, Colors.green),
            const SizedBox(height: 12),
          ],
          if (_editableProfile.aiWeaknesses != null) ...[
            _buildInsightItem('Areas to Improve', _editableProfile.aiWeaknesses!, Colors.orange),
            const SizedBox(height: 12),
          ],
          if (_editableProfile.aiRecommendations != null) ...[
            _buildInsightItem('Recommendations', _editableProfile.aiRecommendations!, Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
