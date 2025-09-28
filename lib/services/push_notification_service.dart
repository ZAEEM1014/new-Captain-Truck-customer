import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firebase_service.dart';
import '../services/auth_user_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  // Initialize push notifications
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      // Save token to user profile in Firestore
      if (_fcmToken != null && AuthUserService.isLoggedIn) {
        await _saveTokenToUserProfile(_fcmToken!);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps when app is terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        if (AuthUserService.isLoggedIn) {
          _saveTokenToUserProfile(newToken);
        }
      });

      print('Push notifications initialized successfully');
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }

  // Save FCM token to user profile
  static Future<void> _saveTokenToUserProfile(String token) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser != null) {
        await FirebaseService.updateUserData(currentUser.uid, {
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now(),
        });
        print('FCM token saved to user profile');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');

    // You can show a local notification here if needed
    // For now, the app will handle it through the real-time streams
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.notification?.title}');

    // Handle background message processing
    // This runs in a separate isolate
  }

  // Handle notification taps
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');

    // Navigate to appropriate screen based on notification data
    if (message.data.containsKey('tripId')) {
      final tripId = message.data['tripId'];
      // Navigate to trip details screen
      // This would need to be implemented with a navigation service
      print('Navigate to trip: $tripId');
    }
  }

  // Subscribe to topic (for general notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // Get current FCM token
  static String? get fcmToken => _fcmToken;

  // Update token when user logs in
  static Future<void> updateTokenOnLogin() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveTokenToUserProfile(token);
      }
    } catch (e) {
      print('Error updating token on login: $e');
    }
  }

  // Clear token when user logs out
  static Future<void> clearTokenOnLogout() async {
    try {
      _fcmToken = null;
      // Optionally, remove token from user profile in Firestore
    } catch (e) {
      print('Error clearing token on logout: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  // Handle background message
}
