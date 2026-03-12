import '../../../../core/utils/date_utils.dart';

class ExperienceModel {
  final int? id;
  final String company;
  final String position;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool currentlyWorking;
  final String? description;
  final List<String>? achievements;
  final List<String>? technologies;
  final bool? extractedFromCV;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExperienceModel({
    this.id,
    required this.company,
    required this.position,
    this.location,
    this.startDate,
    this.endDate,
    this.currentlyWorking = false,
    this.description,
    this.achievements,
    this.technologies,
    this.extractedFromCV,
    this.createdAt,
    this.updatedAt,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] as int?,
      company: json['company'] as String,
      position: json['position'] as String,
      location: json['location'] as String?,
      startDate: json['startDate'] != null
          ? parseServerDateTime(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? parseServerDateTime(json['endDate'] as String)
          : null,
      currentlyWorking: json['currentlyWorking'] as bool? ?? false,
      description: json['description'] as String?,
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      technologies: (json['technologies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'company': company,
      'position': position,
      if (location != null) 'location': location,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'currentlyWorking': currentlyWorking,
      if (description != null) 'description': description,
      if (achievements != null) 'achievements': achievements,
      if (technologies != null) 'technologies': technologies,
      if (extractedFromCV != null) 'extractedFromCV': extractedFromCV,
    };
  }

  String get duration {
    if (startDate == null) return 'Duration not specified';

    final start = startDate!;
    final end = currentlyWorking ? DateTime.now() : (endDate ?? DateTime.now());

    final years = end.year - start.year;
    final months = end.month - start.month;

    final totalMonths = (years * 12) + months;
    final durationYears = totalMonths ~/ 12;
    final durationMonths = totalMonths % 12;

    if (durationYears == 0 && durationMonths == 0) {
      return 'Less than a month';
    } else if (durationYears == 0) {
      return '$durationMonths ${durationMonths == 1 ? 'month' : 'months'}';
    } else if (durationMonths == 0) {
      return '$durationYears ${durationYears == 1 ? 'year' : 'years'}';
    } else {
      return '$durationYears ${durationYears == 1 ? 'year' : 'years'} $durationMonths ${durationMonths == 1 ? 'month' : 'months'}';
    }
  }

  String get periodString {
    if (startDate == null) return 'Period not specified';

    final start = '${_monthName(startDate!.month)} ${startDate!.year}';
    final end = currentlyWorking
        ? 'Present'
        : endDate != null
            ? '${_monthName(endDate!.month)} ${endDate!.year}'
            : 'Present';

    return '$start - $end';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
