import '../../../../core/network/dio_client.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DioClient _dioClient;

  NotificationRepositoryImpl(this._dioClient);

  @override
  Future<List<NotificationEntity>> getAllNotifications() async {
    try {
      final response = await _dioClient.dio.get('/api/notifications');
      final List<dynamic> data = response.data as List;
      return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications() async {
    try {
      final response = await _dioClient.dio.get('/api/notifications/unread');
      final List<dynamic> data = response.data as List;
      return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch unread notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/api/notifications/unread/count');
      return response.data as int;
    } catch (e) {
      throw Exception('Failed to fetch unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dioClient.dio.put('/api/notifications/$notificationId/read');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.put('/api/notifications/read-all');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }
}
