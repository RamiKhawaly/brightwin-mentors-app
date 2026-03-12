class MentorSettingsRequest {
  final String mentorSeniority; // REQUIRED: Mentor's own seniority level
  final List<String>? canMentorLevels; // Which candidate levels they can mentor
  final bool availableForSessions; // REQUIRED: Availability status
  final List<String>? interviewLanguages; // Languages for interviews

  MentorSettingsRequest({
    required this.mentorSeniority,
    this.canMentorLevels,
    required this.availableForSessions,
    this.interviewLanguages,
  });

  Map<String, dynamic> toJson() {
    return {
      'mentorSeniority': mentorSeniority,
      if (canMentorLevels != null && canMentorLevels!.isNotEmpty)
        'canMentorLevels': canMentorLevels,
      'availableForSessions': availableForSessions,
      if (interviewLanguages != null && interviewLanguages!.isNotEmpty)
        'interviewLanguages': interviewLanguages,
    };
  }
}
