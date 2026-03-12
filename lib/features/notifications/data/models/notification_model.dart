import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/notification.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.isRead,
    super.actionUrl,
    super.relatedEntityId,
    super.relatedEntityType,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Backend sends 'description' field, which can be null
    final description = json['description'] as String?;
    final message = json['message'] as String?;

    // Use description if available, fallback to message, or use title as last resort
    final notificationMessage = description ?? message ?? json['title'] as String? ?? 'No details available';

    return NotificationModel(
      id: json['id'] as int,
      type: _notificationTypeFromString(json['type'] as String),
      title: json['title'] as String? ?? 'Notification',
      message: notificationMessage,
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      relatedEntityId: json['relatedEntityId'] as int?,
      relatedEntityType: json['relatedEntityType'] as String?,
      createdAt: parseServerDateTime(json['createdAt'] as String),
      updatedAt: parseServerDateTime(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static NotificationType _notificationTypeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'SESSION_REQUESTED':
        return NotificationType.sessionRequested;
      case 'SESSION_TIME_SLOTS_PROPOSED':
        return NotificationType.sessionTimeSlotsProposed;
      case 'SESSION_CONFIRMED':
        return NotificationType.sessionConfirmed;
      case 'SESSION_CANCELLED':
        return NotificationType.sessionCancelled;
      case 'SESSION_RESCHEDULED':
        return NotificationType.sessionRescheduled;
      case 'SESSION_REMINDER':
        return NotificationType.sessionReminder;
      case 'JOB_APPLICATION_STATUS':
        return NotificationType.jobApplicationStatus;
      case 'MESSAGE_RECEIVED':
        return NotificationType.messageReceived;
      default:
        return NotificationType.general;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.sessionRequested:
        return 'SESSION_REQUESTED';
      case NotificationType.sessionTimeSlotsProposed:
        return 'SESSION_TIME_SLOTS_PROPOSED';
      case NotificationType.sessionConfirmed:
        return 'SESSION_CONFIRMED';
      case NotificationType.sessionCancelled:
        return 'SESSION_CANCELLED';
      case NotificationType.sessionRescheduled:
        return 'SESSION_RESCHEDULED';
      case NotificationType.sessionReminder:
        return 'SESSION_REMINDER';
      case NotificationType.jobApplicationStatus:
        return 'JOB_APPLICATION_STATUS';
      case NotificationType.messageReceived:
        return 'MESSAGE_RECEIVED';
      case NotificationType.general:
        return 'GENERAL';
    }
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      isRead: entity.isRead,
      actionUrl: entity.actionUrl,
      relatedEntityId: entity.relatedEntityId,
      relatedEntityType: entity.relatedEntityType,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
