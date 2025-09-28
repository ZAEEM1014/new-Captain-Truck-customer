import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static bool _isInitialized = false;

  // Initialize Firebase services
  static Future<bool> initialize() async {
    try {
      if (!_isInitialized) {
        await Firebase.initializeApp();
        _analytics = FirebaseAnalytics.instance;
        _isInitialized = true;
        print('✅ Firebase initialized successfully');
        return true;
      }
      return true;
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      return false;
    }
  }

  // Get Analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  // Log custom events
  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logEvent(name: eventName, parameters: parameters);
        print('📊 Analytics event logged: $eventName');
      }
    } catch (e) {
      print('❌ Failed to log event: $e');
    }
  }

  // Log screen views
  static Future<void> logScreenView(String screenName) async {
    try {
      if (_analytics != null) {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenName,
        );
        print('📱 Screen view logged: $screenName');
      }
    } catch (e) {
      print('❌ Failed to log screen view: $e');
    }
  }

  // Log user login
  static Future<void> logLogin(String loginMethod) async {
    try {
      if (_analytics != null) {
        await _analytics!.logLogin(loginMethod: loginMethod);
        print('👤 Login event logged: $loginMethod');
      }
    } catch (e) {
      print('❌ Failed to log login: $e');
    }
  }

  // Log custom user events
  static Future<void> logUserAction(
    String action, {
    Map<String, dynamic>? parameters,
  }) async {
    await logEvent(
      'user_action',
      parameters: {
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?parameters,
      },
    );
  }

  // Update user data in Firestore
  static Future<void> updateUserData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .update(data);
      print('📝 User data updated for: $uid');
    } catch (e) {
      print('❌ Failed to update user data: $e');
      // If document doesn't exist, create it
      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(uid)
            .set(data, SetOptions(merge: true));
        print('📝 User data created/merged for: $uid');
      } catch (e2) {
        print('❌ Failed to create/merge user data: $e2');
      }
    }
  }

  // Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
}
