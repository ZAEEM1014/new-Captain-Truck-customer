import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomSelectableField extends StatelessWidget {
  final String value;
  final String hint;
  final VoidCallback onTap;

  const CustomSelectableField({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value.isEmpty ? hint : value,
              style: TextStyle(
                color: value.isEmpty
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
