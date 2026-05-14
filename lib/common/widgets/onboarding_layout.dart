import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class OnboardingLayout extends StatelessWidget {
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final bool isLoading;
  final bool showBackButton;
  final String? nextButtonText;

  const OnboardingLayout({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.isLoading = false,
    this.showBackButton = true,
    this.nextButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileIncomplete) {
          String route = '/personal-info';
          if (state.step == 2) route = '/venue-type';
          if (state.step == 3) route = '/venue-details';
          if (state.step == 4) route = '/ground-court-info';
          if (state.step == 5) route = '/amenities';
          if (state.step == 6) route = '/slot-config';
          if (state.step == 7) route = '/pricing-setup';
          if (state.step == 8) route = '/kyc-documentation';
          if (state.step == 9) route = '/photos-media';
          if (state.step == 10) route = '/review-submit';

          // Only navigate if it's a different step than the current one
          if (state.step != currentStep) {
            Navigator.pushReplacementNamed(context, route);
          }
        }
        if (state is AuthDocumentsRequired) {
          Navigator.pushReplacementNamed(context, '/upload-documents');
        }
        if (state is AuthSuccess) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      },
      child: Scaffold(
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
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Row(
            children: List.generate(10, (index) {
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
          const AppSizedBox(height: 20),
          AppText(
            text: "Step $currentStep of 10",
            size: 14,
            color: Colors.white70,
            weight: FontWeight.w500,
          ),
          const AppSizedBox(height: 8),
          AppText(
            text: title,
            size: 28,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
          const AppSizedBox(height: 4),
          AppText(text: subtitle, size: 14, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (showBackButton) ...[
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => context.read<AuthCubit>().checkDocumentStatus(
                forceStep: currentStep - 1,
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen.withOpacity(0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
          ),
          const AppSizedBox(width: 16),
        ],
        Expanded(
          flex: 3,
          child: AppButton(
            title: nextButtonText ?? "Save & Next",
            isLoading: isLoading,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}
