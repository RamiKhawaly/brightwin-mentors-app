import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_request_model.dart';
import '../models/job_response_model.dart';
import '../models/job_import_request.dart';
import '../models/job_async_task_response.dart';
import '../models/job_import_status_response.dart';

class JobRepositoryImpl implements JobRepository {
  final DioClient _dioClient;

  JobRepositoryImpl(this._dioClient);

  @override
  Future<JobResponseModel> createJob(JobRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/jobs',
        data: request.toJson(),
      );
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> importJobFromUrl(JobImportRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/jobs/from-url',
        data: request.toJson(),
      );
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobAsyncTaskResponse> startUnassignedJobImport(JobImportRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/jobs/unassigned',
        data: request.toJson(),
      );
      return JobAsyncTaskResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobImportStatusResponse> getUnassignedJobImportStatus(String taskId) async {
    try {
      final response = await _dioClient.dio.get('/api/jobs/unassigned/status/$taskId');
      return JobImportStatusResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> approveJob(int id) async {
    try {
      final response = await _dioClient.dio.post('/api/jobs/$id/approve');
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> rejectJob(int id) async {
    try {
      await _dioClient.dio.post('/api/jobs/$id/reject');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> publishJob(int id) async {
    try {
      final response = await _dioClient.dio.post('/api/jobs/$id/publish');
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> unpublishJob(int id) async {
    try {
      final response = await _dioClient.dio.post('/api/jobs/$id/unpublish');
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JobResponseModel>> getMyJobs() async {
    try {
      final response = await _dioClient.dio.get('/api/jobs/my-jobs');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => JobResponseModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> getJobById(int id) async {
    try {
      final response = await _dioClient.dio.get('/api/jobs/$id');
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> updateJob(int id, JobRequestModel request) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/jobs/$id',
        data: request.toJson(),
      );
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteJob(int id) async {
    try {
      await _dioClient.dio.delete('/api/jobs/$id');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> updateJobStatus(int id, String status) async {
    try {
      final response = await _dioClient.dio.patch(
        '/api/jobs/$id/status',
        data: {'status': status},
      );
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JobResponseModel>> searchJobs(String keyword, {String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'keyword': keyword,
        if (status != null) 'status': status,
      };
      final response = await _dioClient.dio.get(
        '/api/jobs/search',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => JobResponseModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JobResponseModel>> getUnassignedCompanyJobs() async {
    try {
      final response = await _dioClient.dio.get('/api/jobs/unassigned/my-company');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => JobResponseModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JobResponseModel> takeOwnership(int id) async {
    try {
      final response = await _dioClient.dio.post('/api/jobs/$id/take-ownership');
      return JobResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
