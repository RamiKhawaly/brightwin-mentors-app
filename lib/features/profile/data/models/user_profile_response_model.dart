import 'experience_model.dart';
import 'education_model.dart';

enum SeniorityLevel {
  INTERN,
  JUNIOR,
  MID_LEVEL,
  SENIOR,
  LEAD,
  PRINCIPAL,
  MANAGER,
  DIRECTOR,
  VP,
  CXO
}

extension SeniorityLevelExtension on SeniorityLevel {
  String get displayName {
    switch (this) {
      case SeniorityLevel.INTERN:
        return 'Intern';
      case SeniorityLevel.JUNIOR:
        return 'Junior';
      case SeniorityLevel.MID_LEVEL:
        return 'Mid-Level';
      case SeniorityLevel.SENIOR:
        return 'Senior';
      case SeniorityLevel.LEAD:
        return 'Lead';
      case SeniorityLevel.PRINCIPAL:
        return 'Principal';
      case SeniorityLevel.MANAGER:
        return 'Manager';
      case SeniorityLevel.DIRECTOR:
        return 'Director';
      case SeniorityLevel.VP:
        return 'VP';
      case SeniorityLevel.CXO:
        return 'CXO';
    }
  }
}

class UserProfileResponseModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? workEmail;
  final bool? phoneVerified;
  final bool? emailVerified;
  final String role;
  final String? provider;
  final String? imageUrl;
  final bool? active;

  // Profile Information
  final String? bio;
  final String? location;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? currentJobTitle;
  final CompanyResponse? currentCompany;
  final int? yearsOfExperience;

  // Mentor Specific
  final SeniorityLevel? mentorSeniority;
  final List<SeniorityLevel>? canMentorLevels;

  // Work Preferences
  final String? preferredLocation;
  final String? workAvailability;
  final bool? openToRemote;
  final bool? openToRelocation;
  final int? expectedSalaryMin;
  final int? expectedSalaryMax;
  final String? salaryCurrency;

  // Company History and Details
  final List<CompanyExperienceInfo>? companyHistory;
  final CompanyInfo? currentCompanyInfo;
  final List<MentorExperienceInfo>? mentorExperiences;

  // Work Experience, Education, and Skills
  final List<ExperienceModel>? experiences;
  final List<EducationModel>? education;
  final List<SkillInfo>? skills;

  // Rating Information
  final MentorRatingStats? ratingStats;
  final List<MentorRatingResponse>? recentRatings;

  // Session Statistics
  final int? totalSessions;
  final int? completedSessions;
  final double? averageRating;

  // Profile metadata
  final int? profileCompleteness;
  final bool? profileVisible;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileResponseModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.workEmail,
    this.phoneVerified,
    this.emailVerified,
    required this.role,
    this.provider,
    this.imageUrl,
    this.active,
    this.bio,
    this.location,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.currentJobTitle,
    this.currentCompany,
    this.yearsOfExperience,
    this.mentorSeniority,
    this.canMentorLevels,
    this.preferredLocation,
    this.workAvailability,
    this.openToRemote,
    this.openToRelocation,
    this.expectedSalaryMin,
    this.expectedSalaryMax,
    this.salaryCurrency,
    this.companyHistory,
    this.currentCompanyInfo,
    this.mentorExperiences,
    this.experiences,
    this.education,
    this.skills,
    this.ratingStats,
    this.recentRatings,
    this.totalSessions,
    this.completedSessions,
    this.averageRating,
    this.profileCompleteness,
    this.profileVisible,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      workEmail: json['workEmail'] as String?,
      phoneVerified: json['phoneVerified'] as bool?,
      emailVerified: json['emailVerified'] as bool?,
      role: json['role'] as String,
      provider: json['provider'] as String?,
      imageUrl: json['imageUrl'] as String?,
      active: json['active'] as bool?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      linkedInUrl: json['linkedInUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      currentJobTitle: json['currentJobTitle'] as String?,
      currentCompany: json['currentCompany'] != null
          ? CompanyResponse.fromJson(json['currentCompany'] as Map<String, dynamic>)
          : null,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      mentorSeniority: json['mentorSeniority'] != null
          ? SeniorityLevel.values.firstWhere(
              (e) => e.name == json['mentorSeniority'],
              orElse: () => SeniorityLevel.MID_LEVEL,
            )
          : null,
      canMentorLevels: (json['canMentorLevels'] as List<dynamic>?)
          ?.map((e) => SeniorityLevel.values.firstWhere(
                (level) => level.name == e,
                orElse: () => SeniorityLevel.MID_LEVEL,
              ))
          .toList(),
      preferredLocation: json['preferredLocation'] as String?,
      workAvailability: json['workAvailability'] as String?,
      openToRemote: json['openToRemote'] as bool?,
      openToRelocation: json['openToRelocation'] as bool?,
      expectedSalaryMin: json['expectedSalaryMin'] as int?,
      expectedSalaryMax: json['expectedSalaryMax'] as int?,
      salaryCurrency: json['salaryCurrency'] as String?,
      companyHistory: (json['companyHistory'] as List<dynamic>?)
          ?.map((e) => CompanyExperienceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentCompanyInfo: json['currentCompanyInfo'] != null
          ? CompanyInfo.fromJson(json['currentCompanyInfo'] as Map<String, dynamic>)
          : null,
      mentorExperiences: (json['mentorExperiences'] as List<dynamic>?)
          ?.map((e) => MentorExperienceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      experiences: (json['experiences'] as List<dynamic>?)
          ?.map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      education: (json['education'] as List<dynamic>?)
          ?.map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => SkillInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      ratingStats: json['ratingStats'] != null
          ? MentorRatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
      recentRatings: (json['recentRatings'] as List<dynamic>?)
          ?.map((e) => MentorRatingResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSessions: json['totalSessions'] as int?,
      completedSessions: json['completedSessions'] as int?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      profileCompleteness: json['profileCompleteness'] as int?,
      profileVisible: json['profileVisible'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

/// Company response from backend (currentCompany field in profile)
class CompanyResponse {
  final int? id;
  final String name;
  final String? logoUrl;
  final String? websiteUrl;
  final String? linkedInUrl;
  final String? description;
  final String? industry;
  final String? companySize;
  final String? headquarters;
  final bool? verified;
  final int? employeeCount;

  CompanyResponse({
    this.id,
    required this.name,
    this.logoUrl,
    this.websiteUrl,
    this.linkedInUrl,
    this.description,
    this.industry,
    this.companySize,
    this.headquarters,
    this.verified,
    this.employeeCount,
  });

  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    return CompanyResponse(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      linkedInUrl: json['linkedInUrl'] as String?,
      description: json['description'] as String?,
      industry: json['industry'] as String?,
      companySize: json['companySize'] as String?,
      headquarters: json['headquarters'] as String?,
      verified: json['verified'] as bool?,
      employeeCount: json['employeeCount'] as int?,
    );
  }
}

/// Company information model
class CompanyInfo {
  final int? id;
  final String companyName;
  final String? companyLogo;
  final String? linkedInUrl;
  final String? websiteUrl;
  final String? description;
  final String? industry;
  final String? companySize;
  final String? location;
  final String? position;
  final DateTime? startDate;
  final bool? isCurrent;

  CompanyInfo({
    this.id,
    required this.companyName,
    this.companyLogo,
    this.linkedInUrl,
    this.websiteUrl,
    this.description,
    this.industry,
    this.companySize,
    this.location,
    this.position,
    this.startDate,
    this.isCurrent,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] as int?,
      companyName: (json['companyName'] as String?) ?? '',
      companyLogo: json['companyLogo'] as String?,
      linkedInUrl: json['linkedInUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      description: json['description'] as String?,
      industry: json['industry'] as String?,
      companySize: json['companySize'] as String?,
      location: json['location'] as String?,
      position: json['position'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      isCurrent: json['isCurrent'] as bool?,
    );
  }
}

/// Skill information model (from backend)
class SkillInfo {
  final int? id;
  final String skillName;
  final String? category;
  final int? proficiencyLevel;
  final int? yearsOfExperience;

  SkillInfo({
    this.id,
    required this.skillName,
    this.category,
    this.proficiencyLevel,
    this.yearsOfExperience,
  });

  factory SkillInfo.fromJson(Map<String, dynamic> json) {
    return SkillInfo(
      id: json['id'] as int?,
      skillName: (json['name'] ?? json['skillName'] as String?) ?? '',
      category: json['category'] as String?,
      proficiencyLevel: json['proficiencyLevel'] as int?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
    );
  }
}

/// Detailed company experience from UserCompany entity
class CompanyExperienceInfo {
  final int? id;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? currentlyEmployed;
  final String? employmentType;
  final String? location;
  final bool? extractedFromCV;

  // Company details
  final int? companyId;
  final String companyName;
  final String? companyLogo;
  final String? companyWebsite;
  final String? companyLinkedIn;
  final String? companyDescription;
  final String? industry;
  final String? companySize;
  final String? headquarters;
  final bool? companyVerified;

  CompanyExperienceInfo({
    this.id,
    required this.position,
    this.startDate,
    this.endDate,
    this.currentlyEmployed,
    this.employmentType,
    this.location,
    this.extractedFromCV,
    this.companyId,
    required this.companyName,
    this.companyLogo,
    this.companyWebsite,
    this.companyLinkedIn,
    this.companyDescription,
    this.industry,
    this.companySize,
    this.headquarters,
    this.companyVerified,
  });

  factory CompanyExperienceInfo.fromJson(Map<String, dynamic> json) {
    return CompanyExperienceInfo(
      id: json['id'] as int?,
      position: (json['position'] as String?) ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      currentlyEmployed: json['currentlyEmployed'] as bool?,
      employmentType: json['employmentType'] as String?,
      location: json['location'] as String?,
      extractedFromCV: json['extractedFromCV'] as bool?,
      companyId: json['companyId'] as int?,
      companyName: (json['companyName'] as String?) ?? '',
      companyLogo: json['companyLogo'] as String?,
      companyWebsite: json['companyWebsite'] as String?,
      companyLinkedIn: json['companyLinkedIn'] as String?,
      companyDescription: json['companyDescription'] as String?,
      industry: json['industry'] as String?,
      companySize: json['companySize'] as String?,
      headquarters: json['headquarters'] as String?,
      companyVerified: json['companyVerified'] as bool?,
    );
  }

  String get periodString {
    if (startDate == null) return 'Present';
    final start = '${_monthName(startDate!.month)} ${startDate!.year}';
    if (currentlyEmployed == true) return '$start - Present';
    if (endDate == null) return start;
    final end = '${_monthName(endDate!.month)} ${endDate!.year}';
    return '$start - $end';
  }

  String get duration {
    if (startDate == null) return '';
    final end = currentlyEmployed == true ? DateTime.now() : (endDate ?? DateTime.now());
    final months = (end.year - startDate!.year) * 12 + (end.month - startDate!.month);
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years == 0) return '$remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
    if (remainingMonths == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years ${years == 1 ? 'year' : 'years'} $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

/// Mentor experience information from MentorExperience entity
class MentorExperienceInfo {
  final int? id;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isCurrent;
  final String? description;

  // MentorCompany details
  final int? mentorCompanyId;
  final String companyName;
  final String? companyWebsite;
  final String? companyLinkedIn;
  final String? industry;
  final String? location;

  MentorExperienceInfo({
    this.id,
    required this.position,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.description,
    this.mentorCompanyId,
    required this.companyName,
    this.companyWebsite,
    this.companyLinkedIn,
    this.industry,
    this.location,
  });

  factory MentorExperienceInfo.fromJson(Map<String, dynamic> json) {
    return MentorExperienceInfo(
      id: json['id'] as int?,
      position: (json['position'] as String?) ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isCurrent: json['isCurrent'] as bool?,
      description: json['description'] as String?,
      mentorCompanyId: json['mentorCompanyId'] as int?,
      companyName: (json['companyName'] as String?) ?? '',
      companyWebsite: json['companyWebsite'] as String?,
      companyLinkedIn: json['companyLinkedIn'] as String?,
      industry: json['industry'] as String?,
      location: json['location'] as String?,
    );
  }

  String get periodString {
    if (startDate == null) return 'Present';
    final start = '${_monthName(startDate!.month)} ${startDate!.year}';
    if (isCurrent == true) return '$start - Present';
    if (endDate == null) return start;
    final end = '${_monthName(endDate!.month)} ${endDate!.year}';
    return '$start - $end';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

/// Mentor rating statistics
class MentorRatingStats {
  final double? averageRating;
  final int? totalRatings;
  final int? fiveStarCount;
  final int? fourStarCount;
  final int? threeStarCount;
  final int? twoStarCount;
  final int? oneStarCount;

  MentorRatingStats({
    this.averageRating,
    this.totalRatings,
    this.fiveStarCount,
    this.fourStarCount,
    this.threeStarCount,
    this.twoStarCount,
    this.oneStarCount,
  });

  factory MentorRatingStats.fromJson(Map<String, dynamic> json) {
    return MentorRatingStats(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalRatings: json['totalRatings'] as int?,
      fiveStarCount: json['fiveStarCount'] as int?,
      fourStarCount: json['fourStarCount'] as int?,
      threeStarCount: json['threeStarCount'] as int?,
      twoStarCount: json['twoStarCount'] as int?,
      oneStarCount: json['oneStarCount'] as int?,
    );
  }
}

/// Individual mentor rating response
class MentorRatingResponse {
  final int? id;
  final int? rating;
  final String? comment;
  final String? userName;
  final String? userImageUrl;
  final DateTime? createdAt;

  MentorRatingResponse({
    this.id,
    this.rating,
    this.comment,
    this.userName,
    this.userImageUrl,
    this.createdAt,
  });

  factory MentorRatingResponse.fromJson(Map<String, dynamic> json) {
    return MentorRatingResponse(
      id: json['id'] as int?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      userName: json['userName'] as String?,
      userImageUrl: json['userImageUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}
