import 'package:equatable/equatable.dart';

enum NotificationType {
  sessionRequested,
  sessionTimeSlotsProposed,
  sessionConfirmed,
  sessionCancelled,
  sessionRescheduled,
  sessionReminder,
  jobApplicationStatus,
  messageReceived,
  general,
}

class NotificationEntity extends Equatable {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final String? actionUrl;
  final int? relatedEntityId;
  final String? relatedEntityType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.actionUrl,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        isRead,
        actionUrl,
        relatedEntityId,
        relatedEntityType,
        createdAt,
        updatedAt,
      ];
}
