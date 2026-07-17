import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool capitalize;

  const StatusBadge({
    super.key,
    required this.status,
    this.capitalize = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.bookingStatusColor(status);
    final bgColor = AppColors.bookingStatusBgColor(status);
    final displayText = capitalize
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        text: displayText,
        color: color,
        size: 12,
        weight: FontWeight.w600,
      ),
    );
  }
}
