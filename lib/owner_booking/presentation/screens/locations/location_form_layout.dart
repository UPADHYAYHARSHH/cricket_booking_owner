import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

const int kLocationFormTotalSteps = 4;

class LocationFormLayout extends StatelessWidget {
  final bool isEdit;
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String? nextLabel;
  final bool isLoading;

  const LocationFormLayout({
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _buildHeader(context),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + AppSizes.lg,
        bottom: AppSizes.xl,
        left: AppSizes.xxl,
        right: AppSizes.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass back button + flow label
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: AppSizes.iconMd,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              AppText(
                text: isEdit ? 'Edit Location' : 'Add New Location',
                size: 15,
                color: AppColors.white.withValues(alpha: 0.8),
                weight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          // Animated progress bar
          Row(
            children: List.generate(kLocationFormTotalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep - 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: isCurrent ? 5 : 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [AppColors.white, Color(0xFFB9F6CA)],
                          )
                        : null,
                    color: isCompleted
                        ? null
                        : AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.lg),
          AppText(
            text: 'Step $currentStep of $kLocationFormTotalSteps',
            size: 13,
            color: AppColors.white.withValues(alpha: 0.7),
            weight: FontWeight.w500,
          ),
          const SizedBox(height: AppSizes.xs),
          AppText(
            text: title,
            size: 26,
            color: AppColors.white,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: AppSizes.xs),
          AppText(
            text: subtitle,
            size: 13,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
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
                (currentStep == kLocationFormTotalSteps
                    ? (isEdit ? 'Save Changes' : 'Submit')
                    : 'Next'),
            isLoading: isLoading,
            onTap: onNext,
            backgroundColor: AppColors.primaryDarkGreen,
          ),
        ),
      ],
    );
  }
}
