import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColors.primaryDarkGreen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: accentColor, size: AppSizes.iconMd),
        ),
        const SizedBox(width: AppSizes.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(text: title, size: 16, weight: FontWeight.w700),
            if (subtitle != null)
              AppText(
                text: subtitle!,
                size: 12,
                color: AppColors.textSecondaryLight,
              ),
          ],
        ),
      ],
    );
  }
}
