import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImage;
  final String? company;
  final String? jobTitle;
  final bool isMentor;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImage,
    this.company,
    this.jobTitle,
    required this.isMentor,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phoneNumber,
        profileImage,
        company,
        jobTitle,
        isMentor,
        createdAt,
      ];
}
