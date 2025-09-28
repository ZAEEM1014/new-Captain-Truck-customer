import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'custom_animation.dart';

class SuccessPopup extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOkPressed;
  final String? logoPath;
  final IconData? icon;

  const SuccessPopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onOkPressed,
    this.logoPath,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideAnimation(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: logoPath != null
                    ? Image.asset(logoPath!, width: 50, height: 50)
                    : Icon(
                        icon ?? Icons.check_circle,
                        color: AppColors.success,
                        size: 40,
                      ),
              ),
              const SizedBox(height: 20),

              // Icon (if provided)
              if (icon != null) ...[
                Icon(icon!, color: AppColors.textPrimary, size: 32),
                const SizedBox(height: 20),
              ],

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // OK Button
              GestureDetector(
                onTap: onOkPressed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onOkPressed,
    String? logoPath,
    IconData? icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: title,
        subtitle: subtitle,
        onOkPressed: onOkPressed,
        logoPath: logoPath,
        icon: icon,
      ),
    );
  }
}
