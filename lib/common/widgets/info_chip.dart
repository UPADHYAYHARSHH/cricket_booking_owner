import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class InfoChip extends StatelessWidget {
  final dynamic icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon is IconData ? icon as IconData : Icons.circle,
          size: 14,
          color: iconColor ?? AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        AppText(
          text: text,
          size: 12,
          color: textColor ?? AppColors.textSecondaryLight,
        ),
      ],
    );
  }
}
