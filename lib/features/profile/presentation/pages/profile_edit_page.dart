import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/profile_preview_model.dart';
import '../../data/models/skill_model.dart';
import '../../data/models/update_profile_request_model.dart';
import '../../data/models/user_profile_response_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../widgets/career_history_editor_widget.dart';
import '../widgets/profile_photo_widget.dart';
import '../widgets/skills_editor_widget.dart';
import 'profile_cv_approval_page.dart';
import 'complete_profile_from_cv_page.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final ProfileRepositoryImpl _profileRepository;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _cvFileUrl;
  String? _currentImageUrl;

  // Basic Info controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _workEmailController;

  // Professional Info controllers
  late final TextEditingController _jobTitleController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkedInController;
  late final TextEditingController _githubController;
  late final TextEditingController _portfolioController;

  // Profile Visibility
  bool _profileVisible = true;

  // Skills & Experiences (editable lists)
  List<SkillPreviewModel> _skills = [];
  List<ExperiencePreviewModel> _experiences = [];

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _profileRepository = ProfileRepositoryImpl(dioClient);

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _workEmailController = TextEditingController();
    _jobTitleController = TextEditingController();
    _experienceController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _linkedInController = TextEditingController();
    _githubController = TextEditingController();
    _portfolioController = TextEditingController();

    _loadProfile();
    _loadCVFileUrl();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workEmailController.dispose();
    _jobTitleController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  // ─── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        _populateFromProfile(profile);
        setState(() {
          _currentImageUrl = profile.imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load profile: $e', retry: _loadProfile);
      }
    }
  }

  void _populateFromProfile(UserProfileResponseModel profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone ?? '';
    _workEmailController.text = profile.workEmail ?? '';
    _jobTitleController.text = profile.currentJobTitle ?? '';
    _experienceController.text = profile.yearsOfExperience?.toString() ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _linkedInController.text = profile.linkedInUrl ?? '';
    _githubController.text = profile.githubUrl ?? '';
    _portfolioController.text = profile.portfolioUrl ?? '';
    _profileVisible = profile.profileVisible ?? true;

    // Convert SkillInfo → SkillPreviewModel
    _skills = (profile.skills ?? []).map((si) {
      SkillLevel? level;
      if (si.proficiencyLevel != null) {
        final lvlIndex = (si.proficiencyLevel! - 1).clamp(0, SkillLevel.values.length - 1);
        level = SkillLevel.values[lvlIndex];
      }
      return SkillPreviewModel(
        name: si.skillName,
        category: si.category,
        level: level,
        yearsOfExperience: si.yearsOfExperience,
      );
    }).toList();

    // Convert CompanyExperienceInfo → ExperiencePreviewModel
    // (The backend returns companyHistory, not experiences, in GET /api/profile)
    _experiences = (profile.companyHistory ?? []).map((ch) {
      return ExperiencePreviewModel(
        company: ch.companyName,
        position: ch.position,
        location: ch.location,
        startDate: ch.startDate,
        endDate: ch.endDate,
        currentlyWorking: ch.currentlyEmployed ?? false,
      );
    }).toList();
  }

  Future<void> _loadCVFileUrl() async {
    try {
      final cvUrl = await _profileRepository.getCVFileUrl();
      if (mounted) setState(() => _cvFileUrl = cvUrl);
    } catch (e) {
      // CV not available yet — silently ignore
    }
  }

  // ─── Save ───────────────────────────────────────────────────────────────────

  Future<void> _handleSaveProfile() async {
    setState(() => _isSaving = true);
    try {
      final request = UpdateProfileRequestModel(
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        workEmail: _workEmailController.text.trim().isNotEmpty
            ? _workEmailController.text.trim()
            : null,
        currentJobTitle: _jobTitleController.text.trim().isNotEmpty
            ? _jobTitleController.text.trim()
            : null,
        yearsOfExperience: _experienceController.text.trim().isNotEmpty
            ? int.tryParse(_experienceController.text.trim())
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        linkedInUrl: _linkedInController.text.trim().isNotEmpty
            ? _linkedInController.text.trim()
            : null,
        githubUrl: _githubController.text.trim().isNotEmpty
            ? _githubController.text.trim()
            : null,
        portfolioUrl: _portfolioController.text.trim().isNotEmpty
            ? _portfolioController.text.trim()
            : null,
        profileVisible: _profileVisible,
      );

      // Run profile update + skills + experiences concurrently
      await Future.wait([
        _profileRepository.updateProfile(request),
        _profileRepository.saveSkills(_skills),
        _profileRepository.saveExperiences(_experiences),
      ]);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Failed to save profile: $e');
      }
    }
  }

  // ─── CV helpers ─────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        await _uploadCVAndExtract(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadCVAndExtract(File cvFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading and extracting CV...'),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      final extractedData = await _profileRepository.uploadAndExtractCV(cvFile);
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileCVApprovalPage(
            extractedData: extractedData,
            onApprove: _handleApproveExtractedData,
            onReject: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CV upload rejected. Please try again.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('Error uploading/extracting CV: $e');
    }
  }

  Future<void> _handleApproveExtractedData(
      UpdateProfileRequestModel request) async {
    try {
      final updatedProfile =
          await _profileRepository.updateProfileFromCV(request);
      if (!mounted) return;
      Navigator.pop(context);
      _populateFromProfile(updatedProfile);
      setState(() {
        _currentImageUrl = updatedProfile.imageUrl;
      });
      await _loadCVFileUrl();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated from CV!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Error updating profile: $e');
    }
  }

  Future<void> _handleDeleteCV() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete CV'),
        content: const Text(
            'Are you sure you want to delete your CV? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _profileRepository.deleteCVFile();
      if (mounted) setState(() => _cvFileUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV deleted successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      _showError('Error deleting CV: $e');
    }
  }

  Future<void> _handleViewCV() async {
    if (_cvFileUrl == null) return;
    try {
      final uri = Uri.parse(_cvFileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('Error viewing CV: $e');
    }
  }

  Future<void> _navigateToCompleteFromCV() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompleteProfileFromCVPage()),
    );
    if (result == true) _loadProfile();
  }

  // ─── Utility ────────────────────────────────────────────────────────────────

  void _showError(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
        action: retry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: retry,
              )
            : null,
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)))
          : SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Photo ─────────────────────────────────────
                    _buildCard(
                      child: ProfilePhotoWidget(
                        imageUrl: _currentImageUrl,
                        displayName:
                            '${_firstNameController.text} ${_lastNameController.text}'
                                .trim(),
                        repository: _profileRepository,
                        onImageUploaded: (url) =>
                            setState(() => _currentImageUrl = url),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── CV Management ─────────────────────────────────────
                    if (_cvFileUrl != null)
                      _buildCVManagementCard()
                    else
                      _buildCompleteFromCVCard(),

                    const SizedBox(height: 16),

                    // ── Basic Info ────────────────────────────────────────
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Email',
                            controller: _emailController,
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Work Email',
                            controller: _workEmailController,
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Professional Info ─────────────────────────────────
                    _buildSectionCard(
                      title: 'Professional Information',
                      icon: Icons.work_outline,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Current Job Title',
                            controller: _jobTitleController,
                            prefixIcon: const Icon(Icons.work_outline),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Years of Experience',
                            controller: _experienceController,
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Bio',
                            controller: _bioController,
                            maxLines: 4,
                            hint: 'Tell us about yourself...',
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Location',
                            controller: _locationController,
                            prefixIcon:
                                const Icon(Icons.location_on_outlined),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'LinkedIn URL',
                            controller: _linkedInController,
                            prefixIcon: const Icon(Icons.link),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'GitHub URL',
                            controller: _githubController,
                            prefixIcon: const Icon(Icons.link),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Portfolio URL',
                            controller: _portfolioController,
                            prefixIcon: const Icon(Icons.link),
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Skills ────────────────────────────────────────────
                    _buildSectionCard(
                      title: 'Skills',
                      icon: Icons.star_outline,
                      child: SkillsEditorWidget(
                        initialSkills: _skills,
                        onChanged: (updated) =>
                            setState(() => _skills = updated.toList()),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Career History ────────────────────────────────────
                    _buildSectionCard(
                      title: 'Career History',
                      icon: Icons.work_history_outlined,
                      child: CareerHistoryEditorWidget(
                        initialExperiences: _experiences,
                        onChanged: (updated) =>
                            setState(() => _experiences = updated.toList()),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Profile Visibility ────────────────────────────────
                    _buildSectionCard(
                      title: 'Profile Visibility',
                      icon: Icons.visibility_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Visible to job seekers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _profileVisible
                                      ? 'Your profile is publicly visible'
                                      : 'Your profile is hidden from job seekers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _profileVisible,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) =>
                                setState(() => _profileVisible = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Save Button ───────────────────────────────────────
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isSaving ? () {} : _handleSaveProfile,
                      isLoading: _isSaving,
                      icon: Icons.save,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Section card helper ─────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── CV section widgets ──────────────────────────────────────────────────

  Widget _buildCompleteFromCVCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToCompleteFromCV,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Profile with AI',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload CV to auto-fill experience, education & skills',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCVManagementCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CV Uploaded',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your CV is attached to your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleViewCV,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View CV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: BorderSide(
                          color: AppTheme.successColor.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAndUploadCV,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Update'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleDeleteCV,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(
                          color: AppTheme.errorColor.withValues(alpha: 0.5)),
                    ),
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
