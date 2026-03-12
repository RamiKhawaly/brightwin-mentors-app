class CompleteSessionRequest {
  final String feedback;
  final int rating;
  final List<String>? strengths;
  final List<String>? improvements;

  CompleteSessionRequest({
    required this.feedback,
    required this.rating,
    this.strengths,
    this.improvements,
  });

  Map<String, dynamic> toJson() {
    return {
      'feedback': feedback,
      'rating': rating,
      if (strengths != null) 'strengths': strengths,
      if (improvements != null) 'improvements': improvements,
    };
  }
}
