import '../../domain/entities/job_entity.dart';

class JobImportResponse {
  final String title;
  final String company;
  final String description;
  final String requirements;
  final String jobType;
  final String level;
  final String locationType;
  final String? location;
  final double? minSalary;
  final double? maxSalary;
  final String currency;
  final List<String> skills;
  final String sourceUrl;

  JobImportResponse({
    required this.title,
    required this.company,
    required this.description,
    required this.requirements,
    required this.jobType,
    required this.level,
    required this.locationType,
    this.location,
    this.minSalary,
    this.maxSalary,
    this.currency = 'NIS',
    required this.skills,
    required this.sourceUrl,
  });

  factory JobImportResponse.fromJson(Map<String, dynamic> json) {
    return JobImportResponse(
      title: (json['title'] as String).trim(),
      company: (json['company'] as String).trim(),
      description: (json['description'] as String).trim(),
      requirements: (json['requirements'] as String).trim(),
      jobType: (json['jobType'] as String).trim(),
      level: (json['level'] as String).trim(),
      locationType: (json['locationType'] as String).trim(),
      location: (json['location'] as String?)?.trim(),
      minSalary: json['minSalary']?.toDouble(),
      maxSalary: json['maxSalary']?.toDouble(),
      currency: (json['currency'] as String? ?? 'NIS').trim(),
      skills: (json['skills'] as List<dynamic>).map((e) => (e as String).trim()).toList(),
      sourceUrl: (json['sourceUrl'] as String).trim(),
    );
  }

  JobType parseJobType() {
    switch (jobType.toLowerCase()) {
      case 'fulltime':
      case 'full-time':
      case 'full time':
        return JobType.fullTime;
      case 'parttime':
      case 'part-time':
      case 'part time':
        return JobType.partTime;
      case 'contract':
        return JobType.contract;
      case 'internship':
        return JobType.internship;
      default:
        return JobType.fullTime;
    }
  }

  JobLevel parseJobLevel() {
    switch (level.toLowerCase()) {
      case 'entry':
        return JobLevel.entry;
      case 'junior':
        return JobLevel.junior;
      case 'mid':
      case 'middle':
        return JobLevel.mid;
      case 'senior':
        return JobLevel.senior;
      case 'lead':
        return JobLevel.lead;
      case 'principal':
        return JobLevel.principal;
      default:
        return JobLevel.mid;
    }
  }

  JobLocation parseLocationType() {
    switch (locationType.toLowerCase()) {
      case 'remote':
        return JobLocation.remote;
      case 'onsite':
      case 'on-site':
        return JobLocation.onsite;
      case 'hybrid':
        return JobLocation.hybrid;
      default:
        return JobLocation.hybrid;
    }
  }
}
