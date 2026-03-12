import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/mentor_settings_request.dart';
import '../../data/models/mentor_settings_response.dart';

/// Mentor Settings Page
///
/// Integrated with backend API endpoints:
/// - GET  /api/profile/mentor-settings - Load current settings
/// - PUT  /api/profile/mentor-settings - Save settings
///
/// Settings include:
/// - Mentor's own seniority level (required)
/// - Candidate seniority levels they can mentor (optional)
/// - Availability for sessions (required)
/// - Interview languages (optional)
class MentorSettingsPage extends StatefulWidget {
  const MentorSettingsPage({super.key});

  @override
  State<MentorSettingsPage> createState() => _MentorSettingsPageState();
}

class _MentorSettingsPageState extends State<MentorSettingsPage> {
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  bool _isLoading = true;
  bool _isSaving = false;

  // Settings state
  String? _mentorSeniority; // Mentor's own seniority (stored from profile, not editable here)
  bool _availableForMentoring = false;
  final Map<String, bool> _selectedLanguages = {
    'English': false,
    'Hebrew': false,
    'Arabic': false,
  };
  final Map<String, bool> _selectedSeniorityLevels = {
    'INTERN': false,
    'JUNIOR': false,
    'MID_LEVEL': false,
    'SENIOR': false,
    'LEAD': false,
    'PRINCIPAL': false,
    'ARCHITECT': false,
  };

  // Auto-save debouncer to avoid too many API calls
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(_storage);
    _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Fetch mentor seniority from the profile endpoint as fallback
  Future<void> _fetchMentorSeniorityFromProfile() async {
    try {
      print('📡 Fetching mentor seniority from profile...');
      final response = await _dioClient.dio.get('/api/profile');
      print('Profile response: ${response.data}');

      if (response.data != null && response.data['mentorSeniority'] != null) {
        setState(() {
          _mentorSeniority = response.data['mentorSeniority'];
        });
        print('✅ Mentor seniority loaded from profile: $_mentorSeniority');
      } else {
        print('⚠️ No mentor seniority found in profile');
        // Set a default value if still null
        setState(() {
          _mentorSeniority = 'JUNIOR'; // Default fallback
        });
        print('ℹ️ Using default mentor seniority: JUNIOR');
      }
    } catch (e) {
      print('❌ Error fetching mentor seniority from profile: $e');
      // Set a default value on error
      setState(() {
        _mentorSeniority = 'JUNIOR'; // Default fallback
      });
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📡 Loading mentor settings from API...');

      // Call GET /api/profile/mentor-settings
      final response = await _dioClient.dio.get('/api/profile/mentor-settings');

      print('✅ Mentor settings loaded from API');
      print('Response data: ${response.data}');

      final settings = MentorSettingsResponse.fromJson(response.data);

      setState(() {
        // Set mentor's own seniority
        _mentorSeniority = settings.mentorSeniority;

        // Set availability
        _availableForMentoring = settings.availableForSessions;

        // Set interview languages
        for (var lang in settings.interviewLanguages) {
          if (_selectedLanguages.containsKey(lang)) {
            _selectedLanguages[lang] = true;
          }
        }

        // Set candidate seniority levels they can mentor
        for (var level in settings.canMentorLevels) {
          if (_selectedSeniorityLevels.containsKey(level)) {
            _selectedSeniorityLevels[level] = true;
          }
        }

        _isLoading = false;
      });

      print('✅ Settings loaded: mentor seniority=${_mentorSeniority}, available=${_availableForMentoring}');

      // If mentor seniority is null, try to get it from the profile endpoint
      if (_mentorSeniority == null || _mentorSeniority!.isEmpty) {
        print('⚠️ Mentor seniority is null, fetching from profile...');
        await _fetchMentorSeniorityFromProfile();
      }
    } catch (e) {
      print('❌ Error loading mentor settings: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load settings: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Auto-save settings with debouncing to avoid too many API calls
  void _autoSaveSettings() {
    print('🔄 Auto-save triggered');

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Create new timer with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveSettingsToBackend();
    });
  }

  Future<void> _saveSettingsToBackend() async {
    print('💾 _saveSettingsToBackend called. _mentorSeniority = $_mentorSeniority');

    // Skip if mentor seniority is not loaded yet
    if (_mentorSeniority == null || _mentorSeniority!.isEmpty) {
      print('⚠️ Skipping save: mentor seniority is null or empty');

      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your seniority level in your profile first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('💾 Auto-saving mentor settings to API...');

      // Prepare the request data
      final selectedLanguagesList = _selectedLanguages.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final selectedSeniorityLevelsList = _selectedSeniorityLevels.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final request = MentorSettingsRequest(
        mentorSeniority: _mentorSeniority!,
        canMentorLevels: selectedSeniorityLevelsList.isNotEmpty ? selectedSeniorityLevelsList : null,
        availableForSessions: _availableForMentoring,
        interviewLanguages: selectedLanguagesList.isNotEmpty ? selectedLanguagesList : null,
      );

      print('Request body: ${request.toJson()}');

      // Call PUT /api/profile/mentor-settings
      final response = await _dioClient.dio.put(
        '/api/profile/mentor-settings',
        data: request.toJson(),
      );

      print('✅ Settings auto-saved successfully');
      print('Response: ${response.data}');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      print('❌ Error auto-saving mentor settings: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Settings'),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Availability Section
                  _buildSectionCard(
                    context,
                    icon: Icons.online_prediction,
                    title: 'Availability',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set your availability status for mentoring sessions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _availableForMentoring
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _availableForMentoring
                                  ? Colors.green[300]!
                                  : Colors.orange[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _availableForMentoring
                                    ? Icons.check_circle
                                    : Icons.pause_circle,
                                color: _availableForMentoring
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _availableForMentoring
                                          ? 'Available for Mentoring'
                                          : 'Not Available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _availableForMentoring
                                            ? Colors.green[900]
                                            : Colors.orange[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _availableForMentoring
                                          ? 'You can receive mentoring requests'
                                          : 'You won\'t receive new requests',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _availableForMentoring
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _availableForMentoring,
                                onChanged: (value) {
                                  setState(() {
                                    _availableForMentoring = value;
                                  });
                                  _autoSaveSettings();
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the languages you can conduct interviews in',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ..._selectedLanguages.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                              child: CheckboxListTile(
                                title: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: entry.value
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                secondary: Icon(
                                  _getLanguageIcon(entry.key),
                                  color: entry.value
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                                value: entry.value,
                                activeColor: Theme.of(context).primaryColor,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedLanguages[entry.key] = value ?? false;
                                  });
                                  _autoSaveSettings();
                                },
                              ),
                            ),
                          );
                        }),

                        // Show selected count
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSelectedLanguagesCount(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Candidate Seniority Levels Section
                  _buildSectionCard(
                    context,
                    icon: Icons.timeline,
                    title: 'Candidate Seniority Levels',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select which candidate seniority levels you can mentor/interview',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ..._selectedSeniorityLevels.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                              child: CheckboxListTile(
                                title: Text(
                                  _getSeniorityDisplayName(entry.key),
                                  style: TextStyle(
                                    fontWeight: entry.value
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  _getSeniorityDescription(entry.key),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                secondary: Icon(
                                  _getSeniorityIcon(entry.key),
                                  color: entry.value
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                                value: entry.value,
                                activeColor: Theme.of(context).primaryColor,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedSeniorityLevels[entry.key] = value ?? false;
                                  });
                                  _autoSaveSettings();
                                },
                              ),
                            ),
                          );
                        }),

                        // Show selected count
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSelectedSeniorityCount(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
      return 'No languages selected. Please select at least one language.';
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
      return 'No seniority levels selected. Please select at least one level.';
    } else if (selectedCount == 1) {
      return 'You can mentor/interview 1 seniority level';
    } else {
      return 'You can mentor/interview $selectedCount seniority levels';
    }
  }
}
