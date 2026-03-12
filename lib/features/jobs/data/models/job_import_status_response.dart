import 'job_response_model.dart';

class JobImportStatusResponse {
  final String status; // PENDING, COMPLETED, FAILED
  final JobResponseModel? result;
  final String? error;

  JobImportStatusResponse({required this.status, this.result, this.error});

  factory JobImportStatusResponse.fromJson(Map<String, dynamic> json) {
    return JobImportStatusResponse(
      status: json['status'] as String,
      result: json['result'] != null
          ? JobResponseModel.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isPending => status == 'PENDING';
}
