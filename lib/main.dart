import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_service.dart' as firebase;
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'models/user_model.dart';
import 'screens/forgot Password/forgot_password.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'widgets/main_navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await firebase.FirebaseService.initialize();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Push Notifications
  await PushNotificationService.initialize();

  // Initialize Location Services (request permissions)
  await LocationService.initialize();

  runApp(MyApp());
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Handling background message: ${message.notification?.title}');
  // Initialize Firebase if needed
  await firebase.FirebaseService.initialize();

  // You can save the notification to local database or perform other actions
  print('🔔 Background notification data: ${message.data}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Customer App',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => MainNavigationWrapper(),
        '/change_password': (context) => ChangePasswordScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Give some time for splash screen, then start checking auth state
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash during initialization
    if (_isInitializing) {
      return SplashScreen();
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.currentUserStream,
      builder: (context, snapshot) {
        // Show splash screen while loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Check if user is logged in and email is verified
        if (snapshot.hasData && snapshot.data != null) {
          // Initialize notifications for authenticated user
          NotificationService.initializePushNotifications();

          // Check if Firebase user email is verified
          if (AuthService.isEmailVerified) {
            // User is logged in and verified - show dashboard
            return MainNavigationWrapper();
          } else {
            // User is logged in but email not verified - show login with message
            return LoginScreen();
          }
        }

        // No user logged in - show login screen
        return LoginScreen();
      },
    );
  }
}
