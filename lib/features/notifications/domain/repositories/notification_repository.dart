import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getAllNotifications();
  Future<List<NotificationEntity>> getUnreadNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(int notificationId);
  Future<void> markAllAsRead();
}
