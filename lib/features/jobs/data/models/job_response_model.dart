import '../../../../core/utils/date_utils.dart';

class JobResponseModel {
  final int id;
  final String title;
  final String description;
  final String company;
  final String? location;
  final String? employmentType;
  final List<String>? techStack;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final String status;
  final int mentorId;
  final String mentorName;
  final double? referralBonus;
  final String? externalUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int applicationsCount;
  final int? maxApplications;
  final int? remainingSlots;
  final bool isApplicationLimitReached;

  JobResponseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    this.location,
    this.employmentType,
    this.techStack,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    required this.status,
    required this.mentorId,
    required this.mentorName,
    this.referralBonus,
    this.externalUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.applicationsCount,
    this.maxApplications,
    this.remainingSlots,
    this.isApplicationLimitReached = false,
  });

  factory JobResponseModel.fromJson(Map<String, dynamic> json) {
    return JobResponseModel(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as String?) ?? 'Untitled Job',
      description: (json['description'] as String?) ?? '',
      company: (json['company'] as String?) ?? 'Unknown Company',
      location: json['location'] as String?,
      employmentType: json['employmentType'] as String?,
      techStack: (json['techStack'] as List<dynamic>?)?.map((e) => e as String).toList(),
      salaryMin: (json['salaryMin'] as num?)?.toDouble(),
      salaryMax: (json['salaryMax'] as num?)?.toDouble(),
      salaryCurrency: json['salaryCurrency'] as String?,
      status: (json['status'] as String?) ?? 'DRAFT',
      mentorId: json['mentorId'] as int? ?? 0,
      mentorName: (json['mentorName'] as String?) ?? 'Unknown Mentor',
      referralBonus: (json['referralBonus'] as num?)?.toDouble(),
      externalUrl: json['externalUrl'] as String?,
      maxApplications: json['maxApplications'] as int?,
      remainingSlots: json['remainingSlots'] as int?,
      isApplicationLimitReached: json['isApplicationLimitReached'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? parseServerDateTime(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseServerDateTime(json['updatedAt'] as String)
          : DateTime.now(),
      applicationsCount: json['applicationsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'company': company,
      if (location != null) 'location': location,
      if (employmentType != null) 'employmentType': employmentType,
      if (techStack != null) 'techStack': techStack,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (salaryCurrency != null) 'salaryCurrency': salaryCurrency,
      'status': status,
      'mentorId': mentorId,
      'mentorName': mentorName,
      if (referralBonus != null) 'referralBonus': referralBonus,
      if (externalUrl != null) 'externalUrl': externalUrl,
      if (maxApplications != null) 'maxApplications': maxApplications,
      if (remainingSlots != null) 'remainingSlots': remainingSlots,
      'isApplicationLimitReached': isApplicationLimitReached,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'applicationsCount': applicationsCount,
    };
  }
}
