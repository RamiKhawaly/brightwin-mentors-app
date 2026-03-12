class ProfileCVExtractionModel {
  final String? cvFileUrl;
  final String? fileName;
  final String? extractedFullName;
  final String? extractedEmail;
  final String? extractedPhone;
  final String? extractedAddress;
  final String? professionalSummary;
  final String? currentJobTitle;
  final String? currentCompany;
  final int? totalYearsOfExperience;
  final List<String>? extractedSkills;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final double? parsingConfidence;
  final String? parsingStatus;
  final String? message;

  ProfileCVExtractionModel({
    this.cvFileUrl,
    this.fileName,
    this.extractedFullName,
    this.extractedEmail,
    this.extractedPhone,
    this.extractedAddress,
    this.professionalSummary,
    this.currentJobTitle,
    this.currentCompany,
    this.totalYearsOfExperience,
    this.extractedSkills,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.parsingConfidence,
    this.parsingStatus,
    this.message,
  });

  factory ProfileCVExtractionModel.fromJson(Map<String, dynamic> json) {
    return ProfileCVExtractionModel(
      cvFileUrl: json['cvFileUrl'] as String?,
      fileName: json['fileName'] as String?,
      extractedFullName: json['extractedFullName'] as String?,
      extractedEmail: json['extractedEmail'] as String?,
      extractedPhone: json['extractedPhone'] as String?,
      extractedAddress: json['extractedAddress'] as String?,
      professionalSummary: json['professionalSummary'] as String?,
      currentJobTitle: json['currentJobTitle'] as String?,
      currentCompany: json['currentCompany'] as String?,
      totalYearsOfExperience: json['totalYearsOfExperience'] as int?,
      extractedSkills: (json['extractedSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      linkedInUrl: json['linkedInUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      parsingConfidence: (json['parsingConfidence'] as num?)?.toDouble(),
      parsingStatus: json['parsingStatus'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cvFileUrl != null) 'cvFileUrl': cvFileUrl,
      if (fileName != null) 'fileName': fileName,
      if (extractedFullName != null) 'extractedFullName': extractedFullName,
      if (extractedEmail != null) 'extractedEmail': extractedEmail,
      if (extractedPhone != null) 'extractedPhone': extractedPhone,
      if (extractedAddress != null) 'extractedAddress': extractedAddress,
      if (professionalSummary != null)
        'professionalSummary': professionalSummary,
      if (currentJobTitle != null) 'currentJobTitle': currentJobTitle,
      if (currentCompany != null) 'currentCompany': currentCompany,
      if (totalYearsOfExperience != null)
        'totalYearsOfExperience': totalYearsOfExperience,
      if (extractedSkills != null) 'extractedSkills': extractedSkills,
      if (linkedInUrl != null) 'linkedInUrl': linkedInUrl,
      if (githubUrl != null) 'githubUrl': githubUrl,
      if (portfolioUrl != null) 'portfolioUrl': portfolioUrl,
      if (parsingConfidence != null) 'parsingConfidence': parsingConfidence,
      if (parsingStatus != null) 'parsingStatus': parsingStatus,
      if (message != null) 'message': message,
    };
  }

  // Helper to check if extraction was successful
  bool get isExtractionSuccessful =>
      parsingStatus == 'SUCCESS' || parsingStatus == 'PARTIAL_SUCCESS';

  // Helper to split full name into first and last name
  Map<String, String> get splitName {
    if (extractedFullName == null || extractedFullName!.trim().isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }

    final parts = extractedFullName!.trim().split(' ');
    if (parts.length == 1) {
      return {'firstName': parts[0], 'lastName': ''};
    }

    final firstName = parts.first;
    final lastName = parts.sublist(1).join(' ');
    return {'firstName': firstName, 'lastName': lastName};
  }
}
