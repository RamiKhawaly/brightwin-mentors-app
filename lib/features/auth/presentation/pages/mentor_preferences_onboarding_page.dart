import 'package:flutter/material.dart';

/// Mentor Preferences Onboarding Component
///
/// This is a simplified version for the onboarding flow that allows mentors to:
/// - Select which candidate seniority levels they can mentor
/// - Select interview languages they can provide
///
/// This is shown as the third page in the onboarding flow.
class MentorPreferencesOnboardingPage extends StatefulWidget {
  final Map<String, bool> selectedSeniorityLevels;
  final Map<String, bool> selectedLanguages;
  final Function(Map<String, bool> seniorityLevels, Map<String, bool> languages) onPreferencesChanged;

  const MentorPreferencesOnboardingPage({
    super.key,
    required this.selectedSeniorityLevels,
    required this.selectedLanguages,
    required this.onPreferencesChanged,
  });

  @override
  State<MentorPreferencesOnboardingPage> createState() => _MentorPreferencesOnboardingPageState();
}

class _MentorPreferencesOnboardingPageState extends State<MentorPreferencesOnboardingPage> {
  late Map<String, bool> _selectedSeniorityLevels;
  late Map<String, bool> _selectedLanguages;

  @override
  void initState() {
    super.initState();
    _selectedSeniorityLevels = Map.from(widget.selectedSeniorityLevels);
    _selectedLanguages = Map.from(widget.selectedLanguages);
  }

  void _notifyChanges() {
    widget.onPreferencesChanged(_selectedSeniorityLevels, _selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Set Your Preferences',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Help us match you with the right candidates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Seniority Levels Section
          _buildSectionCard(
            context,
            icon: Icons.timeline,
            title: 'Candidate Seniority Levels',
            description: 'Select which candidate levels you can mentor',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._selectedSeniorityLevels.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSeniorityLevels[entry.key] = !entry.value;
                          _notifyChanges();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: entry.value
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: entry.value
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: entry.value ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getSeniorityIcon(entry.key),
                                color: entry.value
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getSeniorityDisplayName(entry.key),
                                      style: TextStyle(
                                        fontWeight: entry.value
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getSeniorityDescription(entry.key),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: entry.value,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedSeniorityLevels[entry.key] = value ?? false;
                                    _notifyChanges();
                                  });
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildInfoBox(
                  context,
                  _getSelectedSeniorityCount(),
                  Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Interview Languages Section
          _buildSectionCard(
            context,
            icon: Icons.language,
            title: 'Interview Languages',
            description: 'Select languages for mock interviews',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._selectedLanguages.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLanguages[entry.key] = !entry.value;
                          _notifyChanges();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: entry.value
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: entry.value
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: entry.value ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getLanguageIcon(entry.key),
                                color: entry.value
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: entry.value
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: entry.value,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedLanguages[entry.key] = value ?? false;
                                    _notifyChanges();
                                  });
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildInfoBox(
                  context,
                  _getSelectedLanguagesCount(),
                  Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Optional Note
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
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change these preferences anytime in settings',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String message, Color baseColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLanguageIcon(String language) {
    switch (language) {
      case 'English':
        return Icons.language;
      case 'Hebrew':
        return Icons.translate;
      case 'Arabic':
        return Icons.record_voice_over;
      default:
        return Icons.language;
    }
  }

  String _getSelectedLanguagesCount() {
    final selectedCount = _selectedLanguages.values.where((v) => v).length;
    if (selectedCount == 0) {
      return 'Select at least one language to continue';
    } else if (selectedCount == 1) {
      return 'You can conduct interviews in 1 language';
    } else {
      return 'You can conduct interviews in $selectedCount languages';
    }
  }

  String _getSeniorityDisplayName(String seniorityKey) {
    switch (seniorityKey) {
      case 'INTERN':
        return 'Intern';
      case 'JUNIOR':
        return 'Junior';
      case 'MID_LEVEL':
        return 'Mid-Level';
      case 'SENIOR':
        return 'Senior';
      case 'LEAD':
        return 'Lead';
      case 'PRINCIPAL':
        return 'Principal';
      case 'ARCHITECT':
        return 'Architect';
      default:
        return seniorityKey;
    }
  }

  String _getSeniorityDescription(String seniorityKey) {
    switch (seniorityKey) {
      case 'INTERN':
        return 'Intern/Trainee level';
      case 'JUNIOR':
        return '0-2 years of experience';
      case 'MID_LEVEL':
        return '2-5 years of experience';
      case 'SENIOR':
        return '5-8 years of experience';
      case 'LEAD':
        return 'Lead/Staff (8-12 years)';
      case 'PRINCIPAL':
        return 'Principal (12+ years)';
      case 'ARCHITECT':
        return 'Architect/Distinguished Engineer';
      default:
        return '';
    }
  }

  IconData _getSeniorityIcon(String seniorityKey) {
    switch (seniorityKey) {
      case 'INTERN':
        return Icons.school;
      case 'JUNIOR':
        return Icons.person;
      case 'MID_LEVEL':
        return Icons.trending_up;
      case 'SENIOR':
        return Icons.workspace_premium;
      case 'LEAD':
        return Icons.groups;
      case 'PRINCIPAL':
        return Icons.emoji_events;
      case 'ARCHITECT':
        return Icons.architecture;
      default:
        return Icons.work;
    }
  }

  String _getSelectedSeniorityCount() {
    final selectedCount = _selectedSeniorityLevels.values.where((v) => v).length;
    if (selectedCount == 0) {
      return 'Select at least one seniority level to continue';
    } else if (selectedCount == 1) {
      return 'You can mentor 1 seniority level';
    } else {
      return 'You can mentor $selectedCount seniority levels';
    }
  }
}
