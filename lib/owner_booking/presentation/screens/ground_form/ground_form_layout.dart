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
                  AppText(
                    text: title,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                    weight: FontWeight.w700,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xs),
                    AppText(
                      text: subtitle,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xl),
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
        top: topPadding + AppSizes.sm,
        bottom: AppSizes.md,
        left: AppSizes.lg,
        right: AppSizes.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDarkGreen, Color(0xFF066B3E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
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
              Expanded(
                child: AppText(
                  text: isEdit ? 'Edit Ground' : 'Add New Ground',
                  size: 15,
                  color: AppColors.white.withValues(alpha: 0.9),
                  weight: FontWeight.w600,
                ),
              ),
              AppText(
                text: 'Step $currentStep / $kGroundFormTotalSteps',
                size: 12,
                color: AppColors.white.withValues(alpha: 0.8),
                weight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: List.generate(kGroundFormTotalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep - 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: isCurrent ? 4 : 3,
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
