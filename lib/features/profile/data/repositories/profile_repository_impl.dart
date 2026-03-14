import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_profile_response_model.dart';
import '../models/profile_cv_extraction_model.dart';
import '../models/profile_preview_model.dart';
import '../models/linkedin_person_response.dart';
import '../models/linkedin_job_response.dart';

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

  // ─── LinkedIn Person Search ─────────────────────────────────────────────

  /// Parses a result payload (list or single map) into [LinkedInPersonResponse].
  /// Filters out entries where all meaningful fields are null (empty server results).
  List<LinkedInPersonResponse> _parsePersonList(dynamic raw) {
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      list = [raw];
    } else {
      return [];
    }
    return list
        .map((e) => LinkedInPersonResponse.fromJson(e as Map<String, dynamic>))
        .where((p) => p.displayName.isNotEmpty || (p.url != null && p.url!.isNotEmpty))
        .toList();
  }

  /// Checks a status-response map for a completed result.
  /// Returns the profiles if status == 'done', throws if 'failed',
  /// returns null if still processing.
  List<LinkedInPersonResponse>? _extractDoneResult(
      Map<String, dynamic> data, String resultKey) {
    final status = data['status']?.toString() ?? 'processing';
    if (status == 'done') {
      final raw = data[resultKey];

      // Key is absent or explicitly null — no data here, let caller try another key
      if (raw == null) return null;

      // Check if the result items are error objects (crawler/proxy errors)
      if (raw is List && raw.isNotEmpty) {
        final allErrors = raw.every(
          (item) => item is Map && item.containsKey('error') && item['error'] != null,
        );
        if (allErrors) {
          final firstError = (raw.first as Map)['error']?.toString() ?? 'LinkedIn search failed';
          throw Exception(firstError);
        }
      }

      final profiles = _parsePersonList(raw);
      print('✅ LinkedIn search done — ${profiles.length} profile(s)');
      return profiles;
    } else if (status == 'failed') {
      final error = data['error']?.toString() ?? 'LinkedIn search failed';
      throw Exception(error);
    }
    return null; // still processing
  }

  /// Step 1: POST /api/linkedin/person/by-name.
  /// Returns (taskId, results): if the server already completed synchronously,
  /// [results] is non-null and no polling is needed. Otherwise poll with [taskId].
  Future<(String, List<LinkedInPersonResponse>?)>
      initiateLinkedInByNameSearch() async {
    try {
      print('🔍 Initiating LinkedIn by-name search');

      final initResponse = await _dioClient.dio.post(
        '/api/linkedin/person/by-name',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final data = initResponse.data as Map<String, dynamic>;
      final taskId = data['taskId']?.toString() ?? '';
      print('📋 LinkedIn by-name taskId: $taskId');

      // Server may return results immediately (status == 'done') in either key
      final immediate = _extractDoneResult(data, 'result') ??
          _extractDoneResult(data, 'rawResult');
      if (immediate != null) {
        print('⚡ LinkedIn by-name returned results immediately');
        return (taskId, immediate);
      }

      return (taskId, null);
    } catch (e) {
      print('❌ Error initiating LinkedIn by-name search: $e');
      rethrow;
    }
  }

  /// Step 2: Poll GET /api/linkedin/person/by-name/{taskId} until done/failed.
  /// The server may put results in either 'result' or 'rawResult'.
  Future<List<LinkedInPersonResponse>> pollLinkedInByNameStatus(
      String taskId) async {
    const pollInterval = Duration(seconds: 30);
    const maxWait = Duration(minutes: 10);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final statusResponse = await _dioClient.dio.get(
        '/api/linkedin/person/by-name/$taskId',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      final data = statusResponse.data as Map<String, dynamic>;
      print('🔄 LinkedIn by-name status: ${data['status']}');

      // Check 'result' first, then fall back to 'rawResult'
      final result = _extractDoneResult(data, 'result') ??
          _extractDoneResult(data, 'rawResult');
      if (result != null) return result;
      // null → still processing, keep polling
    }

    throw Exception('LinkedIn profile search timed out. Please try again.');
  }

  /// Step 1: POST /api/linkedin/person/by-url → one of:
  ///   • { taskId, status: "processing" }        → poll by taskId
  ///   • { status: "done", rawResult: {...} }     → immediate wrapped result
  ///   • { id, name, city, ... }                  → immediate raw profile
  /// Step 2: Poll GET /api/linkedin/person/by-url/{taskId} until done/failed.
  Future<List<LinkedInPersonResponse>> searchLinkedInByUrl(String url) async {
    try {
      print('🔍 Initiating LinkedIn by-URL search: $url');

      final initResponse = await _dioClient.dio.post(
        '/api/linkedin/person/by-url',
        data: {'url': url},
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final data = initResponse.data as Map<String, dynamic>;
      final taskId = data['taskId']?.toString() ?? '';
      print('📋 LinkedIn by-URL full response: $data');
      print('📋 LinkedIn by-URL taskId: $taskId, status: ${data['status']}');

      // Case 1: wrapped result with status == 'done'
      final immediate = _extractDoneResult(data, 'rawResult');
      if (immediate != null) {
        print('⚡ LinkedIn by-URL returned results immediately (wrapped)');
        return immediate;
      }

      // Case 2: response IS the profile directly (no status/rawResult wrapper)
      if (taskId.isEmpty &&
          (data.containsKey('name') ||
              data.containsKey('id') ||
              data.containsKey('full_name'))) {
        print('⚡ LinkedIn by-URL returned raw profile directly');
        return _parsePersonList(data);
      }

      // Case 3: async — poll with taskId
      if (taskId.isEmpty) {
        throw Exception('No taskId returned by server');
      }

      return await _pollLinkedInByUrlStatus(taskId);
    } catch (e) {
      print('❌ Error searching LinkedIn by URL: $e');
      rethrow;
    }
  }

  Future<List<LinkedInPersonResponse>> _pollLinkedInByUrlStatus(
      String taskId) async {
    const pollInterval = Duration(seconds: 5);
    const maxWait = Duration(minutes: 10);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final statusResponse = await _dioClient.dio.get(
        '/api/linkedin/person/by-url/$taskId',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = statusResponse.data as Map<String, dynamic>;
      print('🔄 LinkedIn by-URL status: ${data['status']}');

      // Check wrapped result
      final wrapped = _extractDoneResult(data, 'rawResult');
      if (wrapped != null) return wrapped;

      // Check if response became a raw profile
      if (data.containsKey('name') ||
          data.containsKey('id') ||
          data.containsKey('full_name')) {
        print('✅ LinkedIn by-URL poll returned raw profile');
        return _parsePersonList(data);
      }
      // null → still processing, keep polling
    }

    throw Exception('LinkedIn profile fetch timed out. Please try again.');
  }

  /// Saves a LinkedIn person's data as the mentor's profile.
  /// Updates basic info + saves experiences in batch.
  Future<void> saveLinkedInProfile(LinkedInPersonResponse person) async {
    try {
      print('💾 Saving LinkedIn profile for ${person.displayName}');

      // 1. Basic profile info
      final request = UpdateProfileRequestModel(
        firstName: person.firstName?.isNotEmpty == true
            ? person.firstName
            : person.displayName.split(' ').first,
        lastName: person.lastName?.isNotEmpty == true
            ? person.lastName
            : person.displayName.contains(' ')
                ? person.displayName.split(' ').sublist(1).join(' ')
                : null,
        bio: person.summary,
        location: person.location,
        linkedInUrl: person.url,
        currentJobTitle: person.currentCompany?.title ??
            person.experience
                .where((e) => e.isCurrent)
                .map((e) => e.title)
                .firstOrNull,
        imageUrl: person.imgUrl,
      );

      await _dioClient.dio.put('/api/profile', data: request.toJson());
      print('✅ Basic profile saved');

      // 2. Experiences
      final allExperiences = <Map<String, dynamic>>[];

      // Add currentCompany if present
      if (person.currentCompany != null) {
        final cc = person.currentCompany!;
        final startDt =
            LinkedInExperienceItem.parseDate(cc.startDate);
        allExperiences.add({
          'company': cc.company,
          'position': cc.title,
          if (cc.location != null) 'location': cc.location,
          if (startDt != null) 'startDate': startDt.toIso8601String(),
          'currentlyWorking': true,
        });
      }

      // Add the rest (skip any that are isCurrent to avoid duplicating currentCompany)
      for (final exp in person.experience.where((e) => !e.isCurrent)) {
        final startDt = LinkedInExperienceItem.parseDate(exp.startDate);
        final endDt = LinkedInExperienceItem.parseDate(exp.endDate);
        allExperiences.add({
          'company': exp.company,
          'position': exp.title,
          if (exp.location != null) 'location': exp.location,
          if (startDt != null) 'startDate': startDt.toIso8601String(),
          if (endDt != null) 'endDate': endDt.toIso8601String(),
          'currentlyWorking': false,
          if (exp.description != null) 'description': exp.description,
        });
      }

      if (allExperiences.isNotEmpty) {
        await _dioClient.dio.post(
          '/api/profile/experiences/batch',
          data: {'experiences': allExperiences},
        );
        print('✅ ${allExperiences.length} experiences saved');
      }
    } catch (e) {
      print('❌ Error saving LinkedIn profile: $e');
      rethrow;
    }
  }

  // ─── LinkedIn Jobs ───────────────────────────────────────────────────────

  Future<List<LinkedInJobResponse>> fetchCompanyJobs(
    String companyName,
    String? companyUrl,
  ) async {
    try {
      print('🏢 Fetching jobs for company: $companyName');
      final response = await _dioClient.dio.post(
        '/api/linkedin/jobs',
        data: {
          'companyName': companyName,
          if (companyUrl != null) 'companyUrl': companyUrl,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final list = response.data as List<dynamic>;
      print('✅ Found ${list.length} jobs for $companyName');
      return list
          .map((e) =>
              LinkedInJobResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching company jobs: $e');
      rethrow;
    }
  }

  /// Creates all jobs in the DB. Jobs whose [jobPostingUrl] is in
  /// [ownedUrls] are assigned to the current mentor; others go to the
  /// unassigned pool.
  Future<void> createLinkedInJobsBatch(
    List<LinkedInJobResponse> allJobs,
    Set<String> ownedUrls,
  ) async {
    try {
      print(
          '💼 Creating ${allJobs.length} LinkedIn jobs (${ownedUrls.length} assigned)');

      final payload = allJobs.map((job) {
        final data = job.toJson();
        data['assign'] = ownedUrls.contains(job.jobPostingUrl);
        return data;
      }).toList();

      await _dioClient.dio.post(
        '/api/jobs/linkedin/bulk',
        data: {'jobs': payload},
        options: Options(
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ LinkedIn jobs batch created');
    } catch (e) {
      print('❌ Error creating LinkedIn jobs batch: $e');
      rethrow;
    }
  }

  /// Client-side scrape: sends the raw HTML collected by the in-app WebView
  /// to the backend for AI formatting.  Endpoint: POST /api/linkedin/scrape-html
  Future<ProfilePreviewModel> importProfileFromLinkedInHtml(String html) async {
    try {
      print('🔗 Sending LinkedIn HTML to backend (${html.length} chars)');

      final response = await _dioClient.dio.post(
        '/api/linkedin/scrape-html',
        data: {'html': html},
        options: Options(
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ LinkedIn HTML import response received');
      return ProfilePreviewModel.fromJson(response.data);
    } catch (e) {
      print('❌ Error importing LinkedIn profile from HTML: $e');
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
