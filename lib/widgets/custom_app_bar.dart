import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.elevation = 0.0,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80); // Increased from 70 to 80

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? AppColors.background,
            (backgroundColor ?? AppColors.background).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // Adjusted padding
          child: Row(
            children: [
              if (showBackButton || leading != null) ...[
                leading ??
                    GestureDetector(
                      onTap: onBackPressed ?? () => Navigator.pop(context),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          FontAwesomeIcons.arrowLeft,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: centerTitle
                    ? Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20, // Reduced from 22 to 20
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.5,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // Added overflow handling
                          maxLines: 1, // Ensure single line
                        ),
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20, // Reduced from 22 to 20
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Added overflow handling
                        maxLines: 1, // Ensure single line
                      ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 16),
                Row(children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
