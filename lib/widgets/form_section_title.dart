import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FormSectionTitle extends StatelessWidget {
  final String title;

  const FormSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
