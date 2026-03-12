import 'skill_model.dart';

class ProfilePreviewModel {
  // Personal Information
  final String? fullName;
  final String? email;
  final String? phone;
  final String? location;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;

  // Professional Summary
  final String? professionalSummary;
  final String? currentJobTitle;
  final String? currentCompany;
  final int? totalYearsOfExperience;

  // Extracted Data
  final List<ExperiencePreviewModel> experiences;
  final List<EducationPreviewModel> education;
  final List<SkillPreviewModel> skills;
  final List<String> languages;

  // AI Analysis
  final String? aiAnalysis;
  final double? aiQualityScore;
  final String? aiStrengths;
  final String? aiWeaknesses;
  final String? aiRecommendations;

  ProfilePreviewModel({
    this.fullName,
    this.email,
    this.phone,
    this.location,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.professionalSummary,
    this.currentJobTitle,
    this.currentCompany,
    this.totalYearsOfExperience,
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.languages = const [],
    this.aiAnalysis,
    this.aiQualityScore,
    this.aiStrengths,
    this.aiWeaknesses,
    this.aiRecommendations,
  });

  factory ProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    return ProfilePreviewModel(
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      linkedInUrl: json['linkedInUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      professionalSummary: json['professionalSummary'] as String?,
      currentJobTitle: json['currentJobTitle'] as String?,
      currentCompany: json['currentCompany'] as String?,
      totalYearsOfExperience: json['totalYearsOfExperience'] as int?,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => ExperiencePreviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => EducationPreviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => SkillPreviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      aiAnalysis: json['aiAnalysis'] as String?,
      aiQualityScore: (json['aiQualityScore'] as num?)?.toDouble(),
      aiStrengths: json['aiStrengths'] as String?,
      aiWeaknesses: json['aiWeaknesses'] as String?,
      aiRecommendations: json['aiRecommendations'] as String?,
    );
  }

  Map<String, String> get splitName {
    if (fullName == null || fullName!.trim().isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }

    final parts = fullName!.trim().split(' ');
    if (parts.length == 1) {
      return {'firstName': parts[0], 'lastName': ''};
    }

    final firstName = parts.first;
    final lastName = parts.sublist(1).join(' ');
    return {'firstName': firstName, 'lastName': lastName};
  }
}

class ExperiencePreviewModel {
  final String company;
  final String position;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool currentlyWorking;
  final String? description;
  final List<String> achievements;
  final List<String> technologies;

  ExperiencePreviewModel({
    required this.company,
    required this.position,
    this.location,
    this.startDate,
    this.endDate,
    this.currentlyWorking = false,
    this.description,
    this.achievements = const [],
    this.technologies = const [],
  });

  factory ExperiencePreviewModel.fromJson(Map<String, dynamic> json) {
    return ExperiencePreviewModel(
      company: (json['company'] as String?) ?? '',
      position: (json['position'] as String?) ?? '',
      location: json['location'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      currentlyWorking: json['currentlyWorking'] as bool? ?? false,
      description: json['description'] as String?,
      achievements: (json['achievements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      technologies: (json['technologies'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      if (location != null) 'location': location,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'currentlyWorking': currentlyWorking,
      if (description != null) 'description': description,
      'achievements': achievements,
      'technologies': technologies,
    };
  }
}

class EducationPreviewModel {
  final String institution;
  final String degree;
  final String? fieldOfStudy;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool currentlyStudying;
  final double? gpa;
  final String? grade;
  final String? description;

  EducationPreviewModel({
    required this.institution,
    required this.degree,
    this.fieldOfStudy,
    this.location,
    this.startDate,
    this.endDate,
    this.currentlyStudying = false,
    this.gpa,
    this.grade,
    this.description,
  });

  factory EducationPreviewModel.fromJson(Map<String, dynamic> json) {
    return EducationPreviewModel(
      institution: (json['institution'] as String?) ?? '',
      degree: (json['degree'] as String?) ?? '',
      fieldOfStudy: json['fieldOfStudy'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      currentlyStudying: json['currentlyStudying'] as bool? ?? false,
      gpa: (json['gpa'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      if (fieldOfStudy != null) 'fieldOfStudy': fieldOfStudy,
      if (location != null) 'location': location,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'currentlyStudying': currentlyStudying,
      if (gpa != null) 'gpa': gpa,
      if (grade != null) 'grade': grade,
      if (description != null) 'description': description,
    };
  }
}

class SkillPreviewModel {
  final String name;
  final String? category;
  final SkillLevel? level;
  final int? yearsOfExperience;

  SkillPreviewModel({
    required this.name,
    this.category,
    this.level,
    this.yearsOfExperience,
  });

  factory SkillPreviewModel.fromJson(Map<String, dynamic> json) {
    return SkillPreviewModel(
      name: (json['name'] as String?) ?? '',
      category: json['category'] as String?,
      level: json['level'] != null
          ? SkillLevel.values.firstWhere(
              (e) => e.name == json['level'],
              orElse: () => SkillLevel.INTERMEDIATE,
            )
          : null,
      yearsOfExperience: json['yearsOfExperience'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (category != null) 'category': category,
      if (level != null) 'level': level!.name,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
    };
  }
}
