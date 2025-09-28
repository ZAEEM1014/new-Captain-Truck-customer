import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String hint;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    this.selectedDate,
    required this.hint,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(FontAwesomeIcons.calendar, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : hint,
                style: TextStyle(
                  color: selectedDate != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }
}
