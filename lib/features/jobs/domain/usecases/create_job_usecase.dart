import '../../data/models/job_request_model.dart';
import '../../data/models/job_response_model.dart';
import '../repositories/job_repository.dart';

class CreateJobUseCase {
  final JobRepository _repository;

  CreateJobUseCase(this._repository);

  Future<JobResponseModel> call(JobRequestModel request) async {
    return await _repository.createJob(request);
  }
}
