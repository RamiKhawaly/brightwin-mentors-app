import '../../data/models/job_request_model.dart';
import '../../data/models/job_response_model.dart';
import '../../data/models/job_import_request.dart';
import '../../data/models/job_async_task_response.dart';
import '../../data/models/job_import_status_response.dart';

abstract class JobRepository {
  Future<JobResponseModel> createJob(JobRequestModel request);
  Future<JobResponseModel> importJobFromUrl(JobImportRequest request);
  Future<JobAsyncTaskResponse> startUnassignedJobImport(JobImportRequest request);
  Future<JobImportStatusResponse> getUnassignedJobImportStatus(String taskId);
  Future<JobResponseModel> approveJob(int id);
  Future<void> rejectJob(int id);
  Future<JobResponseModel> publishJob(int id);
  Future<JobResponseModel> unpublishJob(int id);
  Future<List<JobResponseModel>> getMyJobs();
  Future<JobResponseModel> getJobById(int id);
  Future<JobResponseModel> updateJob(int id, JobRequestModel request);
  Future<void> deleteJob(int id);
  Future<JobResponseModel> updateJobStatus(int id, String status);
  Future<List<JobResponseModel>> searchJobs(String keyword, {String? status});
  Future<List<JobResponseModel>> getUnassignedCompanyJobs();
  Future<JobResponseModel> takeOwnership(int id);
}
