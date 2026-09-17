import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

const int kGroundFormTotalSteps = 4;

class GroundFormLayout extends StatelessWidget {
  final bool isEdit;
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String? nextLabel;
  final bool isLoading;

  const GroundFormLayout({
    super.key,
    required this.isEdit,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    required this.onBack,
    this.nextLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                const SizedBox(height: AppSizes.xxxxl),
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        if (currentStep > 1) ...[
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                height: AppSizes.buttonHeightLg,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primaryDarkGreen,
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    AppText(
                      text: 'Back',
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
        ],
        Expanded(
          flex: 3,
          child: AppButton(
            title:
                nextLabel ??
                (currentStep == kGroundFormTotalSteps
                    ? (isEdit ? 'Save Changes' : 'Add Ground')
                    : 'Next'),
            isLoading: isLoading,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}
