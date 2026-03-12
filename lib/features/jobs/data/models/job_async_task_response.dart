class JobAsyncTaskResponse {
  final String taskId;
  final String status;

  JobAsyncTaskResponse({required this.taskId, required this.status});

  factory JobAsyncTaskResponse.fromJson(Map<String, dynamic> json) {
    return JobAsyncTaskResponse(
      taskId: json['taskId'] as String,
      status: json['status'] as String,
    );
  }
}
