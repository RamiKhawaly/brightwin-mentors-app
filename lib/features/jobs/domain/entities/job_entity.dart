import 'package:equatable/equatable.dart';

enum JobType { fullTime, partTime, contract, internship }
enum JobLevel { entry, junior, mid, senior, lead, principal }
enum JobLocation { remote, onsite, hybrid }

class JobEntity extends Equatable {
  final String id;
  final String title;
  final String company;
  final String description;
  final String requirements;
  final JobType jobType;
  final JobLevel level;
  final JobLocation locationType;
  final String? location;
  final double? minSalary;
  final double? maxSalary;
  final String currency;
  final List<String> skills;
  final String mentorId;
  final String mentorName;
  final int referralBonus;
  final DateTime postedAt;
  final DateTime? deadline;
  final bool isActive;
  final int applicationsCount;

  const JobEntity({
    required this.id,
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
    required this.mentorId,
    required this.mentorName,
    required this.referralBonus,
    required this.postedAt,
    this.deadline,
    this.isActive = true,
    this.applicationsCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        company,
        description,
        requirements,
        jobType,
        level,
        locationType,
        location,
        minSalary,
        maxSalary,
        currency,
        skills,
        mentorId,
        mentorName,
        referralBonus,
        postedAt,
        deadline,
        isActive,
        applicationsCount,
      ];
}
