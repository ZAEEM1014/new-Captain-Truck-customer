import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showAppBar;

  const NotificationsScreen({super.key, this.showAppBar = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<NotificationModel>> _notificationsStream;
  late Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificationService.getUserNotificationsStream();
    _unreadCountStream =
        NotificationService.getUnreadNotificationsCountStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.3),
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
        actions: [
          StreamBuilder<int>(
            stream: _unreadCountStream,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: _markAllAsRead,
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear_all') {
                        _showClearAllDialog();
                      }
                    },
                    icon: Container(
                      margin: const EdgeInsets.all(8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        FontAwesomeIcons.ellipsisVertical,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.trash,
                              size: 16,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Clear All Notifications',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          // Show loading only for the first few seconds
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return FutureBuilder(
              future: Future.delayed(Duration(seconds: 2)),
              builder: (context, delaySnapshot) {
                if (delaySnapshot.connectionState == ConnectionState.done) {
                  // After 2 seconds, show empty state if still no data
                  return _buildEmptyState();
                }
                return _buildLoadingState();
              },
            );
          }

          if (snapshot.hasError) {
            print('Notifications error: ${snapshot.error}');
            return _buildErrorState(snapshot.error.toString());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationsList(notifications);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorState([String? errorMessage]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please try again later',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.bell,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications about your trips here',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? Border.all(color: AppColors.cardBorder, width: 1)
            : Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationIconColor(
                  notification.type,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationIconColor(notification.type),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (notification.tripId != null &&
                          notification.tripId!.isNotEmpty)
                        Text(
                          'Trip ID: ${notification.tripId}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      if (notification.tripId == null ||
                          notification.tripId!.isEmpty)
                        SizedBox.shrink(), // Empty space when no trip ID
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleNotificationAction(notification, value),
              itemBuilder: (context) => [
                if (!notification.isRead)
                  PopupMenuItem<String>(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.check,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text('Mark as read', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.trash,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: 14, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
              child: Icon(
                FontAwesomeIcons.ellipsisVertical,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'trip_created':
        return FontAwesomeIcons.plus;
      case 'trip_assigned':
      case 'driver_assigned':
        return FontAwesomeIcons.userCheck;
      case 'trip_started':
        return FontAwesomeIcons.play;
      case 'trip_completed':
        return FontAwesomeIcons.checkCircle;
      case 'trip_cancelled':
        return FontAwesomeIcons.xmark;
      case 'image_uploaded':
        return FontAwesomeIcons.image;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type) {
      case 'trip_created':
        return Colors.orange;
      case 'trip_assigned':
      case 'driver_assigned':
        return AppColors.primary;
      case 'trip_started':
        return Colors.blue;
      case 'trip_completed':
        return Colors.green;
      case 'trip_cancelled':
        return AppColors.error;
      case 'image_uploaded':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      NotificationService.markNotificationAsRead(notification.notificationId);
    }

    // Navigate to trip details or relevant screen
    // Navigator.pushNamed(context, '/trip-details', arguments: notification.tripId);
  }

  void _handleNotificationAction(
    NotificationModel notification,
    String action,
  ) {
    switch (action) {
      case 'mark_read':
        NotificationService.markNotificationAsRead(notification.notificationId);
        break;
      case 'delete':
        NotificationService.deleteNotification(notification.notificationId);
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              FontAwesomeIcons.triangleExclamation,
              color: AppColors.error,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Clear All Notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Are you sure you want to permanently delete all notifications? This action cannot be undone.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() {
    NotificationService.clearAllNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications have been cleared.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _markAllAsRead() {
    NotificationService.markAllNotificationsAsRead();
  }
}
