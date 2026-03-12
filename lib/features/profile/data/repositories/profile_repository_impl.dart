import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_profile_response_model.dart';
import '../models/profile_cv_extraction_model.dart';
import '../models/profile_preview_model.dart';

class ProfileRepositoryImpl {
  final DioClient _dioClient;

  ProfileRepositoryImpl(this._dioClient);

  Future<UserProfileResponseModel> getProfile() async {
    try {
      print('📋 Fetching profile from /api/profile');
      final response = await _dioClient.dio.get('/api/profile');
      print('✅ Profile response received: ${response.statusCode}');
      print('📦 Profile data: ${response.data}');
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  Future<UserProfileResponseModel> updateProfile(UpdateProfileRequestModel request) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/profile',
        data: request.toJson(),
      );
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfileResponseModel> updateProfileImage(String imageUrl) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/profile/image',
        data: {'imageUrl': imageUrl},
      );
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfileResponseModel> uploadProfileImage(File imageFile) async {
    try {
      print('📷 Uploading profile image...');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last.split('\\').last,
        ),
      });

      final response = await _dioClient.dio.post(
        '/api/profile/image/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ Profile image uploaded successfully');
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfileCompleteness() async {
    try {
      final response = await _dioClient.dio.get('/api/profile/completeness');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileCVExtractionModel> uploadAndExtractCV(File cvFile) async {
    try {
      print('📋 Uploading CV for extraction...');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          cvFile.path,
          filename: cvFile.path.split('/').last.split('\\').last,
        ),
      });

      final response = await _dioClient.dio.post(
        '/api/profile/cv/upload-extract',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ CV extraction response received');
      return ProfileCVExtractionModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error uploading/extracting CV: $e');
      rethrow;
    }
  }

  Future<UserProfileResponseModel> updateProfileFromCV(
    UpdateProfileRequestModel request,
  ) async {
    try {
      print('📋 Updating profile from CV data...');

      final response = await _dioClient.dio.put(
        '/api/profile',
        data: request.toJson(),
      );

      print('✅ Profile updated successfully');
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteCVFile() async {
    try {
      print('🗑️ Deleting CV file...');

      await _dioClient.dio.delete('/api/profile/cv');

      print('✅ CV file deleted successfully');
    } catch (e) {
      print('❌ Error deleting CV: $e');
      rethrow;
    }
  }

  Future<String?> getCVFileUrl() async {
    try {
      print('📋 Fetching CV file URL...');

      final response = await _dioClient.dio.get('/api/profile/cv');

      print('✅ CV file URL retrieved');
      return response.data['cvFileUrl'] as String?;
    } catch (e) {
      print('❌ Error fetching CV URL: $e');
      rethrow;
    }
  }

  Future<ProfilePreviewModel> extractProfileFromCV(File cvFile) async {
    try {
      print('🤖 Uploading CV for async profile extraction...');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          cvFile.path,
          filename: cvFile.path.split('/').last.split('\\').last,
        ),
      });

      // Step 1: Submit the extraction task (202 Accepted)
      final submitResponse = await _dioClient.dio.post(
        '/api/cv/extract-profile',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      final taskId = submitResponse.data['taskId'] as String;
      print('📋 Extraction task submitted, taskId: $taskId');

      // Step 2: Poll for completion
      return await _pollExtractionStatus(taskId);
    } catch (e) {
      print('❌ Error extracting profile from CV: $e');
      rethrow;
    }
  }

  Future<ProfilePreviewModel> _pollExtractionStatus(String taskId) async {
    const pollInterval = Duration(seconds: 3);
    const maxWaitTime = Duration(minutes: 5);
    final deadline = DateTime.now().add(maxWaitTime);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final statusResponse = await _dioClient.dio.get(
        '/api/cv/extract-profile/status/$taskId',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = statusResponse.data as Map<String, dynamic>;
      final status = data['status'] as String;

      print('🔄 Extraction status: $status');

      if (status == 'COMPLETED') {
        print('✅ Profile extraction completed');
        return ProfilePreviewModel.fromJson(data['result'] as Map<String, dynamic>);
      } else if (status == 'FAILED') {
        final error = data['error'] as String? ?? 'Extraction failed';
        throw Exception(error);
      }
      // Still PENDING — continue polling
    }

    throw Exception('Profile extraction timed out. Please try again.');
  }

  Future<UserProfileResponseModel> saveExtractedProfile(ProfilePreviewModel preview) async {
    try {
      print('💾 Saving extracted profile data...');

      // Convert preview to update request
      final nameParts = preview.splitName;

      final request = UpdateProfileRequestModel(
        firstName: nameParts['firstName']!.isNotEmpty ? nameParts['firstName'] : null,
        lastName: nameParts['lastName']!.isNotEmpty ? nameParts['lastName'] : null,
        phone: preview.phone,
        workEmail: preview.email,
        bio: preview.professionalSummary,
        location: preview.location,
        linkedInUrl: preview.linkedInUrl,
        githubUrl: preview.githubUrl,
        portfolioUrl: preview.portfolioUrl,
        currentJobTitle: preview.currentJobTitle,
        yearsOfExperience: preview.totalYearsOfExperience,
      );

      final response = await _dioClient.dio.put(
        '/api/profile',
        data: request.toJson(),
      );

      print('✅ Profile saved successfully');
      return UserProfileResponseModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error saving profile: $e');
      rethrow;
    }
  }

  Future<void> saveExperiences(List<ExperiencePreviewModel> experiences) async {
    try {
      print('💾 Saving ${experiences.length} experiences...');

      final data = experiences.map((e) => e.toJson()).toList();

      await _dioClient.dio.post(
        '/api/profile/experiences/batch',
        data: {'experiences': data},
      );

      print('✅ Experiences saved successfully');
    } catch (e) {
      print('❌ Error saving experiences: $e');
      rethrow;
    }
  }

  Future<void> saveEducation(List<EducationPreviewModel> education) async {
    try {
      print('💾 Saving ${education.length} education records...');

      final data = education.map((e) => e.toJson()).toList();

      await _dioClient.dio.post(
        '/api/profile/education/batch',
        data: {'education': data},
      );

      print('✅ Education saved successfully');
    } catch (e) {
      print('❌ Error saving education: $e');
      rethrow;
    }
  }

  Future<void> saveSkills(List<SkillPreviewModel> skills) async {
    try {
      print('💾 Saving ${skills.length} skills...');

      final data = skills.map((s) => s.toJson()).toList();

      await _dioClient.dio.post(
        '/api/profile/skills/batch',
        data: {'skills': data},
      );

      print('✅ Skills saved successfully');
    } catch (e) {
      print('❌ Error saving skills: $e');
      rethrow;
    }
  }

  Future<ProfilePreviewModel> importProfileFromLinkedIn(String linkedinUrl) async {
    try {
      print('🔗 Importing profile from LinkedIn: $linkedinUrl');

      final response = await _dioClient.dio.post(
        '/api/linkedin/preview',
        data: {'linkedInUrl': linkedinUrl},
        options: Options(
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('✅ LinkedIn profile preview received');
      return ProfilePreviewModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error importing LinkedIn profile: $e');
      rethrow;
    }
  }
}
