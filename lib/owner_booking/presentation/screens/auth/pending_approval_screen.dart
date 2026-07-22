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
        } else if (state is AuthLocationRequired) {
           Navigator.pushNamedAndRemoveUntil(context, '/add-location', (route) => false);
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 64,
                    color: AppColors.statusPending,
                  ),
                ),
                const AppSizedBox(height: AppSizes.xl),
                const AppText(
                  text: 'Pending Approval',
                  size: 24,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
                const AppSizedBox(height: AppSizes.md),
                const AppText(
                  text: 'Your venue location has been submitted successfully.\n'
                      'Our team is currently reviewing your application.\n'
                      'This usually takes 24-48 hours.',
                  size: 15,
                  align: TextAlign.center,
                  color: AppColors.textSecondaryLight,
                ),
                const AppSizedBox(height: AppSizes.xxxxl),
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
        ),
      ),
    );
  }
}
