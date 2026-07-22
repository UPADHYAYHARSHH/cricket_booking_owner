import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

/// Shared step progress indicator for the 3-step onboarding flow.
/// [currentStep] is 1, 2, or 3.
Widget buildOnboardingStepIndicator(int currentStep) {
  return Row(
    children: List.generate(3, (i) {
      final step = i + 1;
      final isActive = step == currentStep;
      final isDone = step < currentStep;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? AppColors.primaryDarkGreen
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 4),
          ],
        ),
      );
    }),
  );
}

/// Top bar for onboarding steps: optional back + progress indicator.
/// Pass [onBack] for steps 2–3 (and optionally step 1 → login).
Widget buildOnboardingHeader({required int currentStep, VoidCallback? onBack}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (onBack != null) ...[
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.primaryDarkGreen,
                ),
                const SizedBox(width: AppSizes.xs),
                AppText(
                  text: currentStep > 1 ? 'Previous step' : 'Back',
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.primaryDarkGreen,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
      ],
      buildOnboardingStepIndicator(currentStep),
    ],
  );
}
