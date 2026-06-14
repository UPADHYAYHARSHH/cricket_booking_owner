import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 12),
            AppText(
              text: title,
              size: 14,
              weight: FontWeight.w600,
              color: const Color(0xFF2E6A4F), // Dark green text
            ),
          ],
        ),
      ),
    );
  }
}
