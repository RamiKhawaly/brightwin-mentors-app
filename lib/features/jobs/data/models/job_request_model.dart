class JobRequestModel {
  final String title;
  final String description;
  final String company;
  final String? location;
  final String? employmentType;
  final List<String>? techStack;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final double? referralBonus;
  final String? externalUrl;
  final int? maxApplications;

  JobRequestModel({
    required this.title,
    required this.description,
    required this.company,
    this.location,
    this.employmentType,
    this.techStack,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.referralBonus,
    this.externalUrl,
    this.maxApplications,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'company': company,
      if (location != null) 'location': location,
      if (employmentType != null) 'employmentType': employmentType,
      if (techStack != null && techStack!.isNotEmpty) 'techStack': techStack,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (salaryCurrency != null) 'salaryCurrency': salaryCurrency,
      if (referralBonus != null) 'referralBonus': referralBonus,
      if (maxApplications != null) 'maxApplications': maxApplications,
      if (externalUrl != null) 'externalUrl': externalUrl,
    };
  }

  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    return JobRequestModel(
      title: json['title'] as String,
      description: json['description'] as String,
      company: json['company'] as String,
      location: json['location'] as String?,
      employmentType: json['employmentType'] as String?,
      techStack: (json['techStack'] as List<dynamic>?)?.map((e) => e as String).toList(),
      salaryMin: (json['salaryMin'] as num?)?.toDouble(),
      salaryMax: (json['salaryMax'] as num?)?.toDouble(),
      salaryCurrency: json['salaryCurrency'] as String?,
      maxApplications: json['maxApplications'] as int?,
      referralBonus: (json['referralBonus'] as num?)?.toDouble(),
      externalUrl: json['externalUrl'] as String?,
    );
  }
}
