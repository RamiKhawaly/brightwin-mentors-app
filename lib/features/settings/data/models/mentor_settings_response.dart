class MentorSettingsResponse {
  final int userId;
  final String? mentorSeniority;
  final List<String> canMentorLevels;
  final bool availableForSessions;
  final List<String> interviewLanguages;
  final String? message;

  MentorSettingsResponse({
    required this.userId,
    this.mentorSeniority,
    required this.canMentorLevels,
    required this.availableForSessions,
    required this.interviewLanguages,
    this.message,
  });

  factory MentorSettingsResponse.fromJson(Map<String, dynamic> json) {
    return MentorSettingsResponse(
      userId: json['userId'] as int,
      mentorSeniority: json['mentorSeniority'] as String?,
      canMentorLevels: (json['canMentorLevels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableForSessions: json['availableForSessions'] as bool? ?? true,
      interviewLanguages: (json['interviewLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (mentorSeniority != null) 'mentorSeniority': mentorSeniority,
      'canMentorLevels': canMentorLevels,
      'availableForSessions': availableForSessions,
      'interviewLanguages': interviewLanguages,
      if (message != null) 'message': message,
    };
  }
}
