class SubmitMentorRatingRequest {
  final int mentorId;
  final int? mentorshipSessionId;
  final int expertise;
  final int communication;
  final int helpfulness;
  final int professionalism;
  final int responsiveness;
  final String? review;
  final bool wouldRecommend;

  SubmitMentorRatingRequest({
    required this.mentorId,
    this.mentorshipSessionId,
    required this.expertise,
    required this.communication,
    required this.helpfulness,
    required this.professionalism,
    required this.responsiveness,
    this.review,
    required this.wouldRecommend,
  });

  Map<String, dynamic> toJson() {
    return {
      'mentorId': mentorId,
      if (mentorshipSessionId != null) 'mentorshipSessionId': mentorshipSessionId,
      'expertise': expertise,
      'communication': communication,
      'helpfulness': helpfulness,
      'professionalism': professionalism,
      'responsiveness': responsiveness,
      if (review != null && review!.isNotEmpty) 'review': review,
      'wouldRecommend': wouldRecommend,
    };
  }
}
