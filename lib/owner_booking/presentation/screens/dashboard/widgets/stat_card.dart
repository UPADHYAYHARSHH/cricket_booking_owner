import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F5), // Light greenish background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            AppText(
              text: value,
              size: 20,
              weight: FontWeight.bold,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(height: 4),
            AppText(
              text: label,
              size: 11,
              color: AppColors.primaryDarkGreen,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
