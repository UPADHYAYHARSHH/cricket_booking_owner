import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/app_constants.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_documents_screen.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/utils/auth_navigation_helper.dart';

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
            description: Text('Welcome to ${AppConstants.appName}'),
            autoCloseDuration: const Duration(seconds: 3),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else if (state is AuthStep1Required) {
          Navigator.pushNamedAndRemoveUntil(context, '/onboarding/step1', (route) => false);
        } else if (state is AuthLocationRequired) {
          Navigator.pushNamedAndRemoveUntil(context, '/add-location', (route) => false);
        } else if (state is AuthGroundRequired) {
          AuthNavigationHelper.navigateForAuthState(context, state);
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
          elevation: 0,
          title: const AppText(
            text: 'Account Verification',
            color: AppColors.white,
            size: 18,
            weight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.white),
              tooltip: 'Log out',
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final pendingState = state is AuthPendingApproval ? state : null;
            final isUserVerified = pendingState?.isUserVerified ?? false;
            final isUserRejected = pendingState?.isUserRejected ?? false;
            final userRejectionReason = pendingState?.userRejectionReason;

            final isLocationVerified = pendingState?.isLocationVerified ?? false;
            final isLocationRejected = pendingState?.isLocationRejected ?? false;
            final locationRejectionReason = pendingState?.locationRejectionReason;
            final locationName = pendingState?.locationName ?? 'Venue Location';
            final locationAddress = pendingState?.locationAddress;
            final locationId = pendingState?.locationId;
            final locationData = pendingState?.locationData;

            final completedCount = (isUserVerified ? 1 : 0) + (isLocationVerified ? 1 : 0);
            final hasAnyRejection = isUserRejected || isLocationRejected;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Icon and Status Summary
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        decoration: BoxDecoration(
                          color: hasAnyRejection
                              ? Colors.red.withValues(alpha: 0.1)
                              : (completedCount == 2
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : AppColors.statusPending.withValues(alpha: 0.12)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasAnyRejection
                              ? Icons.error_outline_rounded
                              : (completedCount == 2
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.hourglass_top_rounded),
                          size: 56,
                          color: hasAnyRejection
                              ? Colors.red
                              : (completedCount == 2
                                  ? Colors.green
                                  : AppColors.statusPending),
                        ),
                      ),
                    ),
                    const AppSizedBox(height: AppSizes.lg),
                    AppText(
                      text: hasAnyRejection
                          ? 'Action Required'
                          : 'Verification in Progress',
                      size: 22,
                      weight: FontWeight.w700,
                      align: TextAlign.center,
                      color: AppColors.textPrimaryLight,
                    ),
                    const AppSizedBox(height: AppSizes.xs),
                    AppText(
                      text: 'Your venue requires 2 approvals before opening for customer bookings.',
                      size: 14,
                      align: TextAlign.center,
                      color: AppColors.textSecondaryLight,
                    ),
                    const AppSizedBox(height: AppSizes.md),

                    // Progress indicator pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: completedCount == 2
                              ? Colors.green.withValues(alpha: 0.12)
                              : AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: completedCount == 2
                                ? Colors.green.withValues(alpha: 0.3)
                                : AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 16,
                              color: completedCount == 2
                                  ? Colors.green
                                  : AppColors.primaryDarkGreen,
                            ),
                            const SizedBox(width: 6),
                            AppText(
                              text: '$completedCount of 2 Verifications Completed',
                              size: 13,
                              weight: FontWeight.w600,
                              color: completedCount == 2
                                  ? Colors.green
                                  : AppColors.primaryDarkGreen,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const AppSizedBox(height: AppSizes.xl),

                    // 1. User Verification Card
                    _buildVerificationCard(
                      context: context,
                      stepNumber: '1',
                      title: 'User Verification',
                      subtitle: 'Owner identity & KYC verification',
                      icon: Icons.person_outline_rounded,
                      isVerified: isUserVerified,
                      isRejected: isUserRejected,
                      rejectionReason: userRejectionReason,
                      pendingMessage:
                          'Admin is reviewing your profile and KYC documents.',
                      verifiedMessage:
                          'Owner identity and KYC documents are verified.',
                      rejectedActionLabel: 'Update Personal / KYC Info',
                      onRejectedAction: () {
                        Navigator.pushNamed(context, '/onboarding/step1').then((_) {
                          if (context.mounted) {
                            context.read<AuthCubit>().init();
                          }
                        });
                      },
                    ),

                    const AppSizedBox(height: AppSizes.lg),

                    // 2. Location Verification Card
                    _buildVerificationCard(
                      context: context,
                      stepNumber: '2',
                      title: 'Location Verification',
                      subtitle: locationAddress != null && locationAddress.isNotEmpty
                          ? '$locationName • $locationAddress'
                          : locationName,
                      icon: Icons.storefront_outlined,
                      isVerified: isLocationVerified,
                      isRejected: isLocationRejected,
                      rejectionReason: locationRejectionReason,
                      pendingMessage:
                          'Admin is reviewing your venue location and property documents.',
                      verifiedMessage:
                          'Venue location documents have been verified and approved.',
                      rejectedActionLabel: 'Upload Location Documents',
                      onRejectedAction: () {
                        if (locationId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationDocumentsScreen(
                                locationId: locationId,
                                locationData: locationData,
                              ),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<AuthCubit>().init();
                            }
                          });
                        }
                      },
                      secondaryActionLabel: locationId != null && !isLocationVerified && !isLocationRejected
                          ? 'Upload Documents'
                          : null,
                      onSecondaryAction: locationId != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationDocumentsScreen(
                                    locationId: locationId,
                                    locationData: locationData,
                                  ),
                                ),
                              ).then((_) {
                                if (context.mounted) {
                                  context.read<AuthCubit>().init();
                                }
                              });
                            }
                          : null,
                    ),

                    const AppSizedBox(height: AppSizes.xxl),

                    // Refresh Button
                    AppButton(
                      title: 'Refresh Status',
                      isLoading: state is AuthLoading,
                      backgroundColor: AppColors.primaryDarkGreen,
                      onTap: () {
                        context.read<AuthCubit>().init();
                      },
                    ),

                    const AppSizedBox(height: AppSizes.md),
                    const Center(
                      child: AppText(
                        text: 'Verification usually takes 24 to 48 hours.',
                        size: 13,
                        color: AppColors.textSecondaryLight,
                      ),
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

  Widget _buildVerificationCard({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
    required bool isRejected,
    required String? rejectionReason,
    required String pendingMessage,
    required String verifiedMessage,
    required String rejectedActionLabel,
    required VoidCallback onRejectedAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    final statusColor = isVerified
        ? Colors.green.shade700
        : (isRejected ? Colors.red.shade700 : AppColors.accentOrange);

    final statusBgColor = isVerified
        ? const Color(0xFFE8F5E9)
        : (isRejected ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1));

    final statusLabel = isVerified
        ? 'Verified'
        : (isRejected ? 'Rejected' : 'Under Review');

    final statusIcon = isVerified
        ? Icons.check_circle_rounded
        : (isRejected ? Icons.cancel_rounded : Icons.schedule_rounded);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVerified
                ? Colors.green.withValues(alpha: 0.3)
                : (isRejected
                    ? Colors.red.withValues(alpha: 0.3)
                    : AppColors.borderLight),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with Icon, Title, and Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: '$stepNumber. $title',
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        text: subtitle,
                        size: 13,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Card Body depending on status
            if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason?.isNotEmpty == true
                          ? rejectionReason!
                          : 'Application documents require correction.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(rejectedActionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDarkGreen,
                    side: const BorderSide(color: AppColors.primaryDarkGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onRejectedAction,
                ),
              ),
            ] else if (isVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verifiedMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFF59D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pendingMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(secondaryActionLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDarkGreen,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onSecondaryAction,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
