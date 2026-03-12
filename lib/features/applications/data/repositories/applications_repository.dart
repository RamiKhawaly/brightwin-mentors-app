import '../../../../core/network/dio_client.dart';
import '../models/application_model.dart';
import '../../../jobs/data/models/job_response_model.dart';

class ApplicationsRepository {
  final DioClient _dioClient;

  ApplicationsRepository(this._dioClient);

  /// Get all applications for a specific job
  Future<List<ApplicationModel>> getApplicationsByJob(int jobId) async {
    try {
      print('📡 Fetching applications for job $jobId');
      final response = await _dioClient.dio.get('/api/applications/jobs/$jobId');

      if (response.data == null) {
        print('⚠️ No data received - job might not have any applications');
        return [];
      }

      print('📦 Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      // Handle empty response
      if (response.data is List && (response.data as List).isEmpty) {
        print('✅ Job has 0 applications');
        return [];
      }

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['applications'] ?? response.data['data'] ?? []);

      if (data.isEmpty) {
        print('✅ Job has 0 applications');
        return [];
      }

      print('📦 Parsing ${data.length} applications...');

      final applications = <ApplicationModel>[];
      for (var i = 0; i < data.length; i++) {
        try {
          print('🔍 [CV DEBUG] Raw JSON for application $i: ${data[i]}');
          final app = ApplicationModel.fromJson(data[i] as Map<String, dynamic>);
          applications.add(app);
        } catch (e) {
          print('⚠️ Error parsing application $i: $e');
          print('   Data: ${data[i]}');
          // Continue with next application
        }
      }

      print('✅ Successfully loaded ${applications.length} applications for job $jobId');
      return applications;
    } catch (e, stackTrace) {
      print('❌ Error fetching applications for job $jobId: $e');
      // Don't rethrow - just return empty list so other jobs can continue
      return [];
    }
  }

  /// Get all applications for the logged-in mentor
  /// Fallback approach: Fetch all mentor's jobs, then get applications for each job
  Future<List<ApplicationModel>> getAllApplications() async {
    try {
      print('📡 Fetching all applications for mentor');

      // First, try the direct endpoint if it exists
      try {
        final response = await _dioClient.dio.get('/api/applications/my-jobs-applications');

        if (response.data != null) {
          final List<dynamic> data = response.data is List
              ? response.data
              : (response.data['applications'] ?? response.data['data'] ?? []);

          final applications = data
              .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
              .toList();

          print('✅ Loaded ${applications.length} total applications');
          return applications;
        }
      } catch (e) {
        print('⚠️ Direct endpoint not available, using fallback approach');
      }

      // Fallback: Get all mentor's jobs first
      print('📡 Fetching mentor jobs for applications...');
      final jobsResponse = await _dioClient.dio.get('/api/jobs/my-jobs');

      if (jobsResponse.data == null) {
        print('⚠️ No jobs found');
        return [];
      }

      final List<dynamic> jobsData = jobsResponse.data is List
          ? jobsResponse.data
          : (jobsResponse.data['jobs'] ?? jobsResponse.data['data'] ?? []);

      final jobs = jobsData
          .map((json) => JobResponseModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Found ${jobs.length} jobs, fetching applications...');

      // Fetch applications for each job
      final List<ApplicationModel> allApplications = [];
      for (var job in jobs) {
        try {
          print('🔄 Fetching applications for job: ${job.title} (ID: ${job.id})');
          final applications = await getApplicationsByJob(job.id);
          print('   ✓ Got ${applications.length} applications for this job');
          allApplications.addAll(applications);
        } catch (e) {
          print('⚠️ Error fetching applications for job ${job.id} (${job.title}): $e');
          // Continue with other jobs - this job might not have any applications
        }
      }

      print('✅ Loaded ${allApplications.length} total applications from ${jobs.length} jobs');
      return allApplications;
    } catch (e) {
      print('❌ Error fetching applications: $e');
      rethrow;
    }
  }

  /// Get a single application by ID
  Future<ApplicationModel> getApplicationById(int applicationId) async {
    try {
      print('📡 Fetching application $applicationId');
      final response = await _dioClient.dio.get('/api/applications/$applicationId');

      print('🔍 [CV DEBUG] Raw backend response for application $applicationId:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${response.data}');

      final application = ApplicationModel.fromJson(response.data as Map<String, dynamic>);
      print('✅ Loaded application $applicationId');
      return application;
    } catch (e) {
      print('❌ Error fetching application $applicationId: $e');
      rethrow;
    }
  }

  /// Update application status (mentor side)
  Future<ApplicationModel> updateApplicationStatus(
    int applicationId,
    UpdateApplicationStatusRequest request,
  ) async {
    try {
      print('📡 Updating application $applicationId status to ${request.status}');
      final response = await _dioClient.dio.patch(
        '/api/applications/$applicationId/status',
        queryParameters: {
          'status': request.status,
        },
      );

      final application = ApplicationModel.fromJson(response.data as Map<String, dynamic>);
      print('✅ Updated application $applicationId status');
      return application;
    } catch (e) {
      print('❌ Error updating application status: $e');
      rethrow;
    }
  }

  /// Forward application CV to HR
  Future<ApplicationModel> forwardApplication(
    int applicationId,
    ForwardApplicationRequest request,
  ) async {
    try {
      print('📡 Forwarding application $applicationId');
      final response = await _dioClient.dio.post(
        '/api/applications/$applicationId/forward',
        data: request.toJson(),
      );

      final application = ApplicationModel.fromJson(response.data as Map<String, dynamic>);
      print('✅ Forwarded application $applicationId');
      return application;
    } catch (e) {
      print('❌ Error forwarding application: $e');
      rethrow;
    }
  }

  /// Delete/reject application
  Future<void> deleteApplication(int applicationId) async {
    try {
      print('📡 Deleting application $applicationId');
      await _dioClient.dio.delete('/api/applications/$applicationId');
      print('✅ Deleted application $applicationId');
    } catch (e) {
      print('❌ Error deleting application: $e');
      rethrow;
    }
  }
}
