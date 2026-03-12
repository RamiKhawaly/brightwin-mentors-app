import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late final NotificationRepositoryImpl _repository;
  late final DioClient _dioClient;
  late TabController _tabController;

  List<NotificationEntity> _allNotifications = [];
  List<NotificationEntity> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Set<int> _expandedNotifications = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dioClient = DioClient(const FlutterSecureStorage());
    _repository = NotificationRepositoryImpl(_dioClient);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allNotifs = await _repository.getAllNotifications();
      final unreadNotifs = await _repository.getUnreadNotifications();
      final count = await _repository.getUnreadCount();

      if (mounted) {
        setState(() {
          _allNotifications = allNotifs;
          _unreadNotifications = unreadNotifs;
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadNotifications();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshNotifications,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.backgroundSecondary,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      if (_allNotifications.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_allNotifications.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unread'),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationList(_allNotifications),
                      _buildNotificationList(_unreadNotifications),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationEntity> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppTheme.textHintColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final isExpanded = _expandedNotifications.contains(notification.id);
    final notificationColor = _getNotificationColor(notification.type);

    // Check if message is meaningful (not same as title and not the fallback)
    final hasMessage = notification.message.isNotEmpty &&
                       notification.message != notification.title &&
                       notification.message != 'No details available';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.backgroundSecondary
              : notificationColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            setState(() {
              if (isExpanded) {
                _expandedNotifications.remove(notification.id);
              } else {
                _expandedNotifications.add(notification.id);
              }
            });

            if (!notification.isRead) {
              await _markAsRead(notification.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(notification.type),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(left: 8, right: 8),
                                  decoration: BoxDecoration(
                                    color: notificationColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (!isExpanded) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.textHintColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(notification.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textHintColor,
                                          fontSize: 12,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedNotifications.remove(notification.id);
                          } else {
                            _expandedNotifications.add(notification.id);
                          }
                        });

                        if (!notification.isRead) {
                          _markAsRead(notification.id);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isExpanded ? 'Collapse' : 'Expand',
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (hasMessage) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDetailedDateTime(notification.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (notification.relatedEntityType != null && notification.relatedEntityId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToRelatedEntity(notification),
                        icon: Icon(
                          _getRelatedEntityIcon(notification.relatedEntityType!),
                          size: 18,
                        ),
                        label: Text(_getRelatedEntityLabel(notification.relatedEntityType!)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRelatedEntityIcon(String entityType) {
    switch (entityType.toUpperCase()) {
      case 'SESSION':
        return Icons.event_rounded;
      case 'JOB':
        return Icons.work_rounded;
      case 'MESSAGE':
        return Icons.message_rounded;
      default:
        return Icons.open_in_new;
    }
  }

  String _getRelatedEntityLabel(String entityType) {
    switch (entityType.toUpperCase()) {
      case 'SESSION':
        return 'View Session Details';
      case 'JOB':
        return 'View Job Posting';
      case 'MESSAGE':
        return 'View Message';
      default:
        return 'View Details';
    }
  }

  void _navigateToRelatedEntity(NotificationEntity notification) {
    if (notification.relatedEntityType == null || notification.relatedEntityId == null) {
      return;
    }

    switch (notification.relatedEntityType!.toUpperCase()) {
      case 'SESSION':
        context.push('/sessions/${notification.relatedEntityId}');
        break;
      case 'JOB':
        // TODO: Navigate to job details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job navigation coming soon')),
        );
        break;
      case 'MESSAGE':
        // TODO: Navigate to messages
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message navigation coming soon')),
        );
        break;
      default:
        if (notification.actionUrl != null) {
          // TODO: Handle action URL
        }
    }
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Format: "Monday, October 29, 2025 at 6:51 PM"
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dateTime.weekday - 1];
    final month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (difference.inDays == 0) {
      return 'Today at $hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday at $hour:$minute $period';
    } else {
      return '$weekday, $month ${dateTime.day}, ${dateTime.year} at $hour:$minute $period';
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.sessionRequested:
      case NotificationType.sessionTimeSlotsProposed:
      case NotificationType.sessionConfirmed:
        return AppTheme.primaryColor;
      case NotificationType.sessionCancelled:
        return AppTheme.errorColor;
      case NotificationType.sessionRescheduled:
        return AppTheme.warningColor;
      case NotificationType.sessionReminder:
        return AppTheme.warningColor;
      case NotificationType.jobApplicationStatus:
        return AppTheme.secondaryColor;
      case NotificationType.messageReceived:
        return AppTheme.primaryColor;
      case NotificationType.general:
        return AppTheme.textSecondaryColor;
    }
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.sessionRequested:
      case NotificationType.sessionTimeSlotsProposed:
      case NotificationType.sessionConfirmed:
        icon = Icons.event_rounded;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.sessionCancelled:
        icon = Icons.event_busy_rounded;
        color = AppTheme.errorColor;
        break;
      case NotificationType.sessionRescheduled:
        icon = Icons.event_repeat_rounded;
        color = AppTheme.warningColor;
        break;
      case NotificationType.sessionReminder:
        icon = Icons.notifications_active_rounded;
        color = AppTheme.warningColor;
        break;
      case NotificationType.jobApplicationStatus:
        icon = Icons.work_rounded;
        color = AppTheme.secondaryColor;
        break;
      case NotificationType.messageReceived:
        icon = Icons.message_rounded;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.general:
        icon = Icons.info_rounded;
        color = AppTheme.textSecondaryColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
