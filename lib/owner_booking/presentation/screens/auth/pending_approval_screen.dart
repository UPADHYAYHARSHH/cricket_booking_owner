import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:toastification/toastification.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Account Approved!'),
            description: const Text('Welcome to TurfPro Owner'),
            autoCloseDuration: const Duration(seconds: 3),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else if (state is AuthRejected) {
          // Stay on this screen, the build method will show rejection UI
        } else if (state is AuthStep1Required) {
          Navigator.pushNamedAndRemoveUntil(context, '/onboarding/step1', (route) => false);
        } else if (state is AuthLocationRequired) {
           Navigator.pushNamedAndRemoveUntil(context, '/add-location', (route) => false);
        } else if (state is AuthGroundRequired) {
          // Let splash handle it
          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        } else if (state is AuthUnauthenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Error'),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDarkGreen,
          title: const AppText(
            text: 'Account Status',
            color: AppColors.white,
            size: 20,
            weight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.white),
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isRejected = state is AuthRejected;
            final rejectionReason = isRejected ? state.reason : '';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.red.withValues(alpha: 0.1)
                            : AppColors.statusPending.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                        size: 64,
                        color: isRejected ? Colors.red : AppColors.statusPending,
                      ),
                    ),
                    const AppSizedBox(height: AppSizes.xl),
                    AppText(
                      text: isRejected ? 'Application Rejected' : 'Pending Approval',
                      size: 24,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                    const AppSizedBox(height: AppSizes.md),
                    if (isRejected && rejectionReason.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha:0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha:0.2)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                AppText(
                                  text: 'Rejection Reason',
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AppText(
                              text: rejectionReason,
                              size: 14,
                              color: AppColors.textPrimaryLight,
                            ),
                          ],
                        ),
                      ),
                      const AppSizedBox(height: AppSizes.md),
                      const AppText(
                        text: 'Please update your details and resubmit.',
                        size: 15,
                        align: TextAlign.center,
                        color: AppColors.textSecondaryLight,
                      ),
                    ] else ...[
                      const AppText(
                        text: 'Your venue location has been submitted successfully.\n'
                            'Our team is currently reviewing your application.\n'
                            'This usually takes 24-48 hours.',
                        size: 15,
                        align: TextAlign.center,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                    const AppSizedBox(height: AppSizes.xxxxl),
                    if (isRejected)
                      AppButton(
                        title: 'Edit & Resubmit',
                        backgroundColor: AppColors.primaryDarkGreen,
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/onboarding/step1',
                            (route) => false,
                          );
                        },
                      )
                    else
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return AppButton(
                            title: 'Refresh Status',
                            isLoading: state is AuthLoading,
                            backgroundColor: AppColors.primaryDarkGreen,
                            onTap: () {
                              context.read<AuthCubit>().init();
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
