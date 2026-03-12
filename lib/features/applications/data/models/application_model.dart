import '../../../../core/utils/date_utils.dart';

enum ApplicationStatus {
  SUBMITTED,
  MISSING_CV,
  UNDER_REVIEW,
  FORWARDED_TO_HR,
  HR_CALLED,
  INTERVIEW_SCHEDULED,
  CONTRACT_SIGNED,
  REJECTED,
  WITHDRAWN,
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.SUBMITTED:
        return 'Submitted';
      case ApplicationStatus.MISSING_CV:
        return 'Missing CV';
      case ApplicationStatus.UNDER_REVIEW:
        return 'Under Review';
      case ApplicationStatus.FORWARDED_TO_HR:
        return 'Forwarded';
      case ApplicationStatus.HR_CALLED:
        return 'HR Called';
      case ApplicationStatus.INTERVIEW_SCHEDULED:
        return 'Interview Scheduled';
      case ApplicationStatus.CONTRACT_SIGNED:
        return 'Contract Signed';
      case ApplicationStatus.REJECTED:
        return 'Rejected';
      case ApplicationStatus.WITHDRAWN:
        return 'Withdrawn';
    }
  }

  String get apiValue {
    return toString().split('.').last;
  }

  static ApplicationStatus fromString(String value) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ApplicationStatus.SUBMITTED,
    );
  }
}

class ApplicationModel {
  final int id;
  final int jobId;
  final String jobTitle;
  final String jobCompany;
  final int candidateId;
  final String candidateName;
  final String? candidateEmail;
  final String? candidatePhone;
  final String? candidateImageUrl;
  final String? coverLetter;
  final int? cvId;
  final String? cvFileName;
  final String? cvUrl;
  final ApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final int mentorId;
  final String? mentorName;
  final bool autoForwarded;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.jobCompany,
    required this.candidateId,
    required this.candidateName,
    this.candidateEmail,
    this.candidatePhone,
    this.candidateImageUrl,
    this.coverLetter,
    this.cvId,
    this.cvFileName,
    this.cvUrl,
    required this.status,
    required this.submittedAt,
    this.updatedAt,
    required this.mentorId,
    this.mentorName,
    this.autoForwarded = false,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    // Log the raw JSON to see what backend is sending
    print('🔍 [CV DEBUG] Parsing ApplicationModel from JSON:');
    print('   Application ID: ${json['id']}');
    print('   Candidate: ${json['applicantName'] ?? json['candidateName']}');
    print('   cvId field: ${json['cvId']}');
    print('   cvFileName field: ${json['cvFileName']}');
    print('   cvFileUrl field: ${json['cvFileUrl']}');
    print('   cvUrl field: ${json['cvUrl']}');
    print('   Raw JSON keys: ${json.keys.toList()}');

    // Parse cvId
    final cvId = json['cvId'] as int?;
    final cvFileName = json['cvFileName'] as String?;

    // Try to get CV URL in order of preference:
    // 1. cvFileUrl (what backend sends)
    // 2. cvUrl (fallback for backward compatibility)
    // 3. Construct from cvId if available
    String? cvUrl = (json['cvFileUrl'] as String?) ?? (json['cvUrl'] as String?);

    // If no URL provided but we have a cvId, construct the download URL
    if (cvUrl == null && cvId != null) {
      // We need to get the base URL from environment
      // For now, we'll use a relative path and let the app handle it
      // The actual URL construction will happen in the repository layer
      cvUrl = '/api/cv/download/$cvId';
      print('   ℹ️ Constructed CV URL from cvId: $cvUrl');
    }

    print('   ✅ Final cvUrl value: $cvUrl');
    print('   ${cvUrl == null ? "❌ CV IS NULL" : "✅ CV EXISTS"}');

    return ApplicationModel(
      id: json['id'] as int? ?? 0,
      jobId: json['jobId'] as int? ?? 0,
      jobTitle: (json['jobTitle'] as String?) ?? 'Unknown Job',
      jobCompany: (json['company'] as String?) ?? (json['jobCompany'] as String?) ?? 'Unknown Company',
      candidateId: (json['applicantId'] as int?) ?? (json['candidateId'] as int?) ?? 0,
      candidateName: (json['applicantName'] as String?) ?? (json['candidateName'] as String?) ?? 'Unknown Candidate',
      candidateEmail: (json['applicantEmail'] as String?) ?? (json['candidateEmail'] as String?),
      candidatePhone: (json['applicantPhone'] as String?) ?? (json['candidatePhone'] as String?),
      candidateImageUrl: (json['applicantImageUrl'] as String?) ?? (json['candidateImageUrl'] as String?),
      coverLetter: json['coverLetter'] as String?,
      cvId: cvId,
      cvFileName: cvFileName,
      cvUrl: cvUrl,
      status: ApplicationStatusExtension.fromString((json['status'] as String?) ?? 'SUBMITTED'),
      submittedAt: (json['createdAt'] != null || json['submittedAt'] != null)
          ? parseServerDateTime((json['createdAt'] as String?) ?? (json['submittedAt'] as String))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseServerDateTime(json['updatedAt'] as String)
          : null,
      mentorId: json['mentorId'] as int? ?? 0,
      mentorName: json['mentorName'] as String?,
      autoForwarded: json['autoForwarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobCompany': jobCompany,
      'candidateId': candidateId,
      'candidateName': candidateName,
      if (candidateEmail != null) 'candidateEmail': candidateEmail,
      if (candidatePhone != null) 'candidatePhone': candidatePhone,
      if (candidateImageUrl != null) 'candidateImageUrl': candidateImageUrl,
      if (coverLetter != null) 'coverLetter': coverLetter,
      if (cvId != null) 'cvId': cvId,
      if (cvFileName != null) 'cvFileName': cvFileName,
      if (cvUrl != null) 'cvUrl': cvUrl,
      'status': status.apiValue,
      'submittedAt': submittedAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'mentorId': mentorId,
      if (mentorName != null) 'mentorName': mentorName,
      'autoForwarded': autoForwarded,
    };
  }
}

class UpdateApplicationStatusRequest {
  final String status;
  final String? notes;

  UpdateApplicationStatusRequest({
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }
}

class ForwardApplicationRequest {
  final String? customMessage;
  final String? recipientEmail;

  ForwardApplicationRequest({
    this.customMessage,
    this.recipientEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      // Backend expects 'message' and 'email' fields
      if (customMessage != null) 'message': customMessage,
      if (recipientEmail != null) 'email': recipientEmail,
    };
  }
}
