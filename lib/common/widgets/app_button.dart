import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final bool showArrow;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.accentOrange;
    final fgColor = textColor ?? AppColors.white;

    return SizedBox(
      height: height ?? AppSizes.buttonHeightLg,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: fgColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: AppSizes.iconSm,
                      color: fgColor,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
