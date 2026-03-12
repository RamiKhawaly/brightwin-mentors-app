class SubmitCandidateRatingRequest {
  final int candidateId;
  final int? mentorshipSessionId;
  final int professionalism;
  final int communication;
  final int preparedness;
  final int engagement;
  final int commitment;
  final String? review;
  final bool wouldRecommend;

  SubmitCandidateRatingRequest({
    required this.candidateId,
    this.mentorshipSessionId,
    required this.professionalism,
    required this.communication,
    required this.preparedness,
    required this.engagement,
    required this.commitment,
    this.review,
    required this.wouldRecommend,
  });

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      if (mentorshipSessionId != null) 'mentorshipSessionId': mentorshipSessionId,
      'professionalism': professionalism,
      'communication': communication,
      'preparedness': preparedness,
      'engagement': engagement,
      'commitment': commitment,
      if (review != null && review!.isNotEmpty) 'review': review,
      'wouldRecommend': wouldRecommend,
    };
  }
}
