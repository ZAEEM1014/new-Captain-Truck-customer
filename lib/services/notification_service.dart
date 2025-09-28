import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // Using user subcollections for better data isolation and scalability
  static const String CUSTOMERS_COLLECTION = 'customers';
  static const String NOTIFICATIONS_SUBCOLLECTION = 'notifications';

  // Get real-time stream of notifications for current user using subcollections
  static Stream<List<NotificationModel>> getUserNotificationsStream() {
    final currentUser =
        _auth.currentUser; // Use _auth instead of AuthUserService
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(CUSTOMERS_COLLECTION)
        .doc(currentUser.uid)
        .collection(NOTIFICATIONS_SUBCOLLECTION)
        .orderBy(
          'timestamp',
          descending: true,
        ) // Use timestamp to match your structure
        .snapshots()
        .handleError((error) {
          print('Error in getUserNotificationsStream: $error');
          return [];
        })
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            print('Error parsing notifications: $e');
            return <NotificationModel>[];
          }
        });
  }

  // Get unread notifications count using subcollections
  static Stream<int> getUnreadNotificationsCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(CUSTOMERS_COLLECTION)
        .doc(currentUser.uid)
        .collection(NOTIFICATIONS_SUBCOLLECTION)
        .where(
          'read',
          isEqualTo: false,
        ) // Use 'read' field to match your structure
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read using subcollections
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(NOTIFICATIONS_SUBCOLLECTION)
          .doc(notificationId)
          .update({'read': true}); // Use 'read' field to match your structure

      print('✅ Notification marked as read: $notificationId');
      return true;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for current user using subcollections
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(NOTIFICATIONS_SUBCOLLECTION)
          .where('read', isEqualTo: false) // Use 'read' field
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();

      print('✅ All notifications marked as read');
      return true;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  // Clear all notifications for current user using subcollections
  static Future<bool> clearAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(NOTIFICATIONS_SUBCOLLECTION)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ All notifications cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing all notifications: $e');
      return false;
    }
  }

  // Delete notification using subcollections
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(NOTIFICATIONS_SUBCOLLECTION)
          .doc(notificationId)
          .delete();

      print('✅ Notification deleted: $notificationId');
      return true;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  // Create notification (used by admin/system) - Updated to support admin notifications
  static Future<bool> createNotification({
    required String userId,
    String? tripId, // Made optional for admin notifications
    required String type,
    required String title,
    required String message,
    String? senderId,
    String priority = 'normal',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: '', // Will be auto-generated by Firestore
        userId: userId,
        tripId: tripId,
        type: type,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        senderId: senderId,
        priority: priority,
        additionalData: additionalData,
      );

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(userId)
          .collection(NOTIFICATIONS_SUBCOLLECTION)
          .add(notification.toMap()); // Let Firestore auto-generate the ID

      print('✅ Notification created for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error creating notification: $e');
      return false;
    }
  }

  // Create admin message notification
  static Future<bool> createAdminNotification({
    required String userId,
    required String title,
    required String message,
    String senderId = 'admin_001',
    String priority = 'normal',
  }) async {
    return await createNotification(
      userId: userId,
      type: NotificationType.adminMessage,
      title: title,
      message: message,
      senderId: senderId,
      priority: priority,
    );
  }

  // Initialize push notifications for the current user
  static Future<void> initializePushNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('🔔 Initializing push notifications for user: ${user.uid}');

      // Request permission for notifications
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      print(
        '🔔 Notification permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔔 User granted notification permissions');
      } else {
        print('🔔 User declined notification permissions');
        return;
      }

      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Save token to user document for sending targeted notifications
        await _firestore.collection('customers').doc(user.uid).update({
          'fcmToken': token,
        });
        print('✅ FCM token saved: $token');
      }

      // Handle foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Received foreground message: ${message.notification?.title}');

        if (message.notification != null) {
          print('📱 Title: ${message.notification!.title}');
          print('📱 Body: ${message.notification!.body}');
          // The notification will be shown automatically by the system
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          '📱 Notification tapped (background): ${message.notification?.title}',
        );
        _handleNotificationTap(message);
      });

      // Handle notification when app is terminated
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        print('📱 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // Subscribe to topics for receiving notifications
      subscribeToNotifications();
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
    }
  } // Handle notification tap

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    switch (type) {
      case 'admin_message':
        // Navigate to notifications screen
        break;
      case 'trip_assigned':
        final tripId = message.data['tripId'];
        if (tripId != null) {
          // Navigate to trip details
        }
        break;
      default:
        // Navigate to notifications screen by default
        break;
    }
  }

  // Subscribe to notification topics
  static void subscribeToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    FirebaseMessaging.instance.subscribeToTopic('user_${user.uid}');
    FirebaseMessaging.instance.subscribeToTopic('customers');

    print('✅ Subscribed to notification topics');
  }

  // Helper methods for creating specific notification types
  static Future<bool> createTripAssignedNotification({
    required String customerId,
    required String tripId,
    required String driverName,
    required String truckType,
  }) async {
    return await createNotification(
      userId: customerId,
      tripId: tripId,
      type: NotificationType.tripAssigned,
      title: 'Trip Assigned',
      message: 'Your $truckType trip has been assigned to driver $driverName',
      additionalData: {'driverName': driverName, 'truckType': truckType},
    );
  }

  static Future<bool> createTripStartedNotification({
    required String customerId,
    required String tripId,
    required String driverName,
  }) async {
    return await createNotification(
      userId: customerId,
      tripId: tripId,
      type: NotificationType.tripStarted,
      title: 'Trip Started',
      message: 'Your trip has been started by driver $driverName',
      additionalData: {'driverName': driverName},
    );
  }

  static Future<bool> createTripCompletedNotification({
    required String customerId,
    required String tripId,
    required String driverName,
  }) async {
    return await createNotification(
      userId: customerId,
      tripId: tripId,
      type: NotificationType.tripCompleted,
      title: 'Trip Completed',
      message: 'Your trip has been completed by driver $driverName',
      additionalData: {'driverName': driverName},
    );
  }

  static Future<bool> createTripCancelledNotification({
    required String customerId,
    required String tripId,
    required String reason,
  }) async {
    return await createNotification(
      userId: customerId,
      tripId: tripId,
      type: NotificationType.tripCancelled,
      title: 'Trip Cancelled',
      message: 'Your trip has been cancelled. Reason: $reason',
      additionalData: {'reason': reason},
    );
  }

  static Future<bool> createImageUploadedNotification({
    required String customerId,
    required String tripId,
    required String imageType, // 'pickup', 'delivery', etc.
  }) async {
    return await createNotification(
      userId: customerId,
      tripId: tripId,
      type: NotificationType.imageUploaded,
      title: 'Image Uploaded',
      message: 'New $imageType image has been uploaded for your trip',
      additionalData: {'imageType': imageType},
    );
  }
}
