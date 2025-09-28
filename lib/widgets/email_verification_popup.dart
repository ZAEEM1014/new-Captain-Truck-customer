import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/custom_popup.dart';

class EmailVerificationPopup {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without action
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismissal
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              final isSmallScreen = screenWidth < 360;
              final isMediumScreen = screenWidth < 600;

              // Responsive sizing
              final popupWidth =
                  screenWidth *
                  (isSmallScreen
                      ? 0.9
                      : isMediumScreen
                      ? 0.85
                      : 0.8);
              final popupMaxWidth = isSmallScreen
                  ? 320.0
                  : isMediumScreen
                  ? 400.0
                  : 450.0;

              return Container(
                width: popupWidth > popupMaxWidth ? popupMaxWidth : popupWidth,
                constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 20 : 28,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Email Icon
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          FontAwesomeIcons.envelope,
                          color: AppColors.primary,
                          size: isSmallScreen ? 32 : 40,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Title
                      Text(
                        'Email Verification Required',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Message
                      Text(
                        'Please verify your email before logging in. Check your inbox and click the verification link.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Additional message
                      Text(
                        'Check your email inbox and click the verification link before logging in.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 28),

                      // Buttons
                      Column(
                        children: [
                          // Resend Email Button
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 45 : 50,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _resendVerificationEmail(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.paperPlane,
                                    size: isSmallScreen ? 16 : 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Resend Email',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          // Go to Login Button
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 45 : 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Go to Login',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _resendVerificationEmail(BuildContext context) async {
    try {
      final user = AuthService.currentFirebaseUser;
      if (user != null && !user.emailVerified) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        // Send verification email
        await user.sendEmailVerification();

        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        // Show success message
        CustomPopup.showSuccess(
          context,
          'Email Sent!',
          'Verification email has been sent to ${user.email}. Please check your inbox and spam folder.',
        );
      } else {
        CustomPopup.showError(
          context,
          'Error',
          'Unable to send verification email. Please try logging in again.',
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      CustomPopup.showError(
        context,
        'Error',
        'Failed to send verification email. Please check your internet connection and try again.',
      );
    }
  }
}
