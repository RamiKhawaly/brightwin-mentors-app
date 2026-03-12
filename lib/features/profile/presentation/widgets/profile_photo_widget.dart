import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/profile_repository_impl.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final String? imageUrl;
  final String displayName;
  final ProfileRepositoryImpl repository;
  final void Function(String newImageUrl) onImageUploaded;

  const ProfilePhotoWidget({
    super.key,
    this.imageUrl,
    required this.displayName,
    required this.repository,
    required this.onImageUploaded,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  bool _isUploading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(ProfilePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentImageUrl = widget.imageUrl;
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);

      final file = File(result.files.single.path!);
      final updatedProfile = await widget.repository.uploadProfileImage(file);

      if (mounted) {
        setState(() {
          _currentImageUrl = updatedProfile.imageUrl;
          _isUploading = false;
        });
        if (updatedProfile.imageUrl != null) {
          widget.onImageUploaded(updatedProfile.imageUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String get _initials {
    final parts = widget.displayName.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUpload,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _isUploading
                    ? Container(
                        color: AppTheme.backgroundSecondary,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                      )
                    : _currentImageUrl != null
                        ? Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                          )
                        : _buildInitialsAvatar(),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
