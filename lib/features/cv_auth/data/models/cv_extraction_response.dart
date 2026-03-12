class CVExtractionResponse {
  final String sessionId;
  final String extractedFullName;
  final String extractedEmail;
  final String extractedPhone;
  final String? extractedAddress;
  final List<String> passwordFields;
  final String? professionalSummary;
  final String? currentJobTitle;
  final String? currentCompany;
  final int? totalYearsOfExperience;
  final List<String>? extractedSkills;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final double? parsingConfidence;
  final String parsingStatus;
  final String? message;
  final bool requiresApproval;

  CVExtractionResponse({
    required this.sessionId,
    required this.extractedFullName,
    required this.extractedEmail,
    required this.extractedPhone,
    this.extractedAddress,
    required this.passwordFields,
    this.professionalSummary,
    this.currentJobTitle,
    this.currentCompany,
    this.totalYearsOfExperience,
    this.extractedSkills,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.parsingConfidence,
    required this.parsingStatus,
    this.message,
    required this.requiresApproval,
  });

  factory CVExtractionResponse.fromJson(Map<String, dynamic> json) {
    return CVExtractionResponse(
      sessionId: json['sessionId'] as String,
      extractedFullName: json['extractedFullName'] as String,
      extractedEmail: json['extractedEmail'] as String,
      extractedPhone: json['extractedPhone'] as String,
      extractedAddress: json['extractedAddress'] as String?,
      passwordFields: (json['passwordFields'] as List<dynamic>).map((e) => e as String).toList(),
      professionalSummary: json['professionalSummary'] as String?,
      currentJobTitle: json['currentJobTitle'] as String?,
      currentCompany: json['currentCompany'] as String?,
      totalYearsOfExperience: json['totalYearsOfExperience'] as int?,
      extractedSkills: (json['extractedSkills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      linkedInUrl: json['linkedInUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      parsingConfidence: (json['parsingConfidence'] as num?)?.toDouble(),
      parsingStatus: json['parsingStatus'] as String,
      message: json['message'] as String?,
      requiresApproval: json['requiresApproval'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'extractedFullName': extractedFullName,
      'extractedEmail': extractedEmail,
      'extractedPhone': extractedPhone,
      if (extractedAddress != null) 'extractedAddress': extractedAddress,
      'passwordFields': passwordFields,
      if (professionalSummary != null) 'professionalSummary': professionalSummary,
      if (currentJobTitle != null) 'currentJobTitle': currentJobTitle,
      if (currentCompany != null) 'currentCompany': currentCompany,
      if (totalYearsOfExperience != null) 'totalYearsOfExperience': totalYearsOfExperience,
      if (extractedSkills != null) 'extractedSkills': extractedSkills,
      if (linkedInUrl != null) 'linkedInUrl': linkedInUrl,
      if (githubUrl != null) 'githubUrl': githubUrl,
      if (portfolioUrl != null) 'portfolioUrl': portfolioUrl,
      if (parsingConfidence != null) 'parsingConfidence': parsingConfidence,
      'parsingStatus': parsingStatus,
      if (message != null) 'message': message,
      'requiresApproval': requiresApproval,
    };
  }
}
