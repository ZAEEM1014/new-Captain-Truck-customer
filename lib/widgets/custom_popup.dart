import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomPopup {
  static void show(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSuccess(BuildContext context, String title, String message) {
    show(context, title, message, Icons.check_circle, AppColors.success);
  }

  static void showError(BuildContext context, String title, String message) {
    show(context, title, message, Icons.error, AppColors.error);
  }

  static void showInfo(BuildContext context, String title, String message) {
    show(context, title, message, Icons.info, AppColors.primary);
  }
}

void showCustomPopup(
  BuildContext context, {
  required Widget graphic, // Accepts Icon, Image, etc.
  required String mainText,
  required String subText,
  Widget? centerImage, // Optional image before icon
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = MediaQuery.of(context).size.width * 0.9;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (centerImage != null) ...[
                    centerImage,
                    const SizedBox(height: 16),
                  ],
                  graphic,
                  const SizedBox(height: 16),
                  Text(
                    mainText,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: subText,
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Future.delayed(const Duration(seconds: 2), () {
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).pop();
  });
}
