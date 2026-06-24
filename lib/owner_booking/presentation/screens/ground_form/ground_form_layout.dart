import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

const int kGroundFormTotalSteps = 6;

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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,
                  const AppSizedBox(height: 40),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 20, left: 24, right: 24),
      decoration: const BoxDecoration(color: AppColors.primaryDarkGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow + flow label
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const AppSizedBox(width: 12),
              AppText(
                text: isEdit ? 'Edit Ground' : 'Add New Ground',
                size: 15,
                color: Colors.white70,
                weight: FontWeight.w500,
              ),
            ],
          ),
          const AppSizedBox(height: 16),
          // Progress bar
          Row(
            children: List.generate(kGroundFormTotalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < currentStep
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: 'Step $currentStep of $kGroundFormTotalSteps',
            size: 13,
            color: Colors.white70,
            weight: FontWeight.w500,
          ),
          const AppSizedBox(height: 6),
          AppText(
            text: title,
            size: 26,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
          const AppSizedBox(height: 4),
          AppText(text: subtitle, size: 13, color: Colors.white70),
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
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen.withOpacity(0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back, color: AppColors.primaryDarkGreen),
              ),
            ),
          ),
          const AppSizedBox(width: 16),
        ],
        Expanded(
          flex: 3,
          child: AppButton(
            title: nextLabel ??
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
