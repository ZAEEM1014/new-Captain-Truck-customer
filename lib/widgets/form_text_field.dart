import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';

class FormTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePasswordVisibility;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Function(String)? onChanged;
  final bool enabled;

  const FormTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePasswordVisibility,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: isPassword ? 1 : maxLines,
      onChanged: onChanged,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontFamily: 'Poppins',
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(
                  prefixIcon,
                  color: enabled ? AppColors.primary : AppColors.textTertiary,
                  size: 18,
                ),
              )
            : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: FaIcon(
                  isPasswordVisible
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                onPressed: onTogglePasswordVisibility,
              )
            : null,
        filled: true,
        fillColor: enabled
            ? AppColors.fieldBackground
            : AppColors.fieldBackground.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.fieldBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
    );
  }
}
