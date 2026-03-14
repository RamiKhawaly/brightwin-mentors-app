class LinkedInJobResponse {
  final String? jobPostingUrl;
  final String? title;
  final String? companyName;
  final String? companyUrl;
  final String? companyLogo;
  final String? location;
  final String? description;
  final String? employmentType;
  final String? seniorityLevel;
  final String? postedDate;
  final String? applyUrl;
  final String? salary;
  final String? jobFunctions;
  final String? industries;

  LinkedInJobResponse({
    this.jobPostingUrl,
    this.title,
    this.companyName,
    this.companyUrl,
    this.companyLogo,
    this.location,
    this.description,
    this.employmentType,
    this.seniorityLevel,
    this.postedDate,
    this.applyUrl,
    this.salary,
    this.jobFunctions,
    this.industries,
  });

  factory LinkedInJobResponse.fromJson(Map<String, dynamic> json) {
    return LinkedInJobResponse(
      jobPostingUrl: json['jobPostingUrl'] as String?,
      title: json['title'] as String?,
      companyName: json['companyName'] as String?,
      companyUrl: json['companyUrl'] as String?,
      companyLogo: json['companyLogo'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      employmentType: json['employmentType'] as String?,
      seniorityLevel: json['seniorityLevel'] as String?,
      postedDate: json['postedDate'] as String?,
      applyUrl: json['applyUrl'] as String?,
      salary: json['salary'] as String?,
      jobFunctions: json['jobFunctions'] as String?,
      industries: json['industries'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (jobPostingUrl != null) 'jobPostingUrl': jobPostingUrl,
      if (title != null) 'title': title,
      if (companyName != null) 'companyName': companyName,
      if (companyUrl != null) 'companyUrl': companyUrl,
      if (companyLogo != null) 'companyLogo': companyLogo,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (employmentType != null) 'employmentType': employmentType,
      if (seniorityLevel != null) 'seniorityLevel': seniorityLevel,
      if (postedDate != null) 'postedDate': postedDate,
      if (applyUrl != null) 'applyUrl': applyUrl,
      if (salary != null) 'salary': salary,
      if (jobFunctions != null) 'jobFunctions': jobFunctions,
      if (industries != null) 'industries': industries,
    };
  }
}
