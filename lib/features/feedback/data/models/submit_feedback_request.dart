class SubmitFeedbackRequest {
  final String sessionId;
  final String jobSeekerId;
  final String type;
  final int rating;
  final String comments;
  final List<String> strengths;
  final List<String> areasForImprovement;

  SubmitFeedbackRequest({
    required this.sessionId,
    required this.jobSeekerId,
    required this.type,
    required this.rating,
    required this.comments,
    required this.strengths,
    required this.areasForImprovement,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'jobSeekerId': jobSeekerId,
      'type': type,
      'rating': rating,
      'comments': comments,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
    };
  }
}
