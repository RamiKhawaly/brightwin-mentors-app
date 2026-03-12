import '../../../../core/utils/date_utils.dart';

class EducationModel {
  final int? id;
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
  final bool? extractedFromCV;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EducationModel({
    this.id,
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
    this.extractedFromCV,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id'] as int?,
      institution: json['institution'] as String,
      degree: json['degree'] as String,
      fieldOfStudy: json['fieldOfStudy'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] != null
          ? parseServerDateTime(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? parseServerDateTime(json['endDate'] as String)
          : null,
      currentlyStudying: json['currentlyStudying'] as bool? ?? false,
      gpa: (json['gpa'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      description: json['description'] as String?,
      extractedFromCV: json['extractedFromCV'] as bool?,
      createdAt: json['createdAt'] != null
          ? parseServerDateTime(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? parseServerDateTime(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      if (extractedFromCV != null) 'extractedFromCV': extractedFromCV,
    };
  }

  String get periodString {
    if (startDate == null) return 'Period not specified';

    final start = startDate!.year.toString();
    final end = currentlyStudying
        ? 'Present'
        : endDate != null
            ? endDate!.year.toString()
            : 'Present';

    return '$start - $end';
  }

  String get degreeWithField {
    if (fieldOfStudy != null && fieldOfStudy!.isNotEmpty) {
      return '$degree in $fieldOfStudy';
    }
    return degree;
  }
}
