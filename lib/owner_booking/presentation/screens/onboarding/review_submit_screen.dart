import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';

class ReviewSubmitScreen extends StatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _editStep(int step) {
    context.read<AuthCubit>().checkDocumentStatus(forceStep: step);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final personal = _data ?? {};
    final venueType = _data?['sports_config'] as Map? ?? {};
    final venueDetails = _data ?? {};
    final groundConfig = _data?['ground_config'] as Map? ?? {};
    final slotConfig = _data?['slot_config'] as Map? ?? {};
    final pricingConfig = _data?['pricing_config'] as Map? ?? {};
    final kycConfig = _data?['kyc_config'] as Map? ?? {};
    final mediaConfig = _data?['media_config'] as Map? ?? {};

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return OnboardingLayout(
          currentStep: 10,
          title: "Review & Submit",
          subtitle: "Verify your details before going live",
          isLoading: state is AuthLoading,
          nextButtonText: "Submit Application",
          onNext: () => context.read<AuthCubit>().submitApplication(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSuccessBanner(),
              const AppSizedBox(height: 32),

              _buildSectionHeader("PERSONAL INFO", 1),
              _buildReviewRow("Owner", personal['owner_name'] ?? "N/A"),
              _buildReviewRow(
                "Mobile",
                "${personal['owner_phone'] ?? 'N/A'} ✓",
              ),
              _buildReviewRow("Email", personal['owner_email'] ?? "N/A"),

              const AppSizedBox(height: 32),
              _buildSectionHeader("VENUE", 2),
              _buildReviewRow("Name", venueDetails['venue_name'] ?? "N/A"),
              _buildReviewRow("Sports", venueType.keys.join(", ")),
              _buildReviewRow("Address", venueDetails['address'] ?? "N/A"),

              const AppSizedBox(height: 32),
              _buildSectionHeader("SLOTS & PRICING", 6),
              _buildReviewRow(
                "Hours",
                "${slotConfig['opening_time'] ?? 'N/A'} – ${slotConfig['closing_time'] ?? 'N/A'}",
              ),
              _buildReviewRow(
                "Slot duration",
                slotConfig['slot_duration'] ?? "N/A",
              ),

              const AppSizedBox(height: 32),
              _buildSectionHeader("DOCUMENTS", 8),
              _buildReviewStatusRow("PAN", kycConfig['pan_url'] != null),
              _buildReviewStatusRow(
                "Property docs",
                kycConfig['property_url'] != null,
              ),
              _buildReviewStatusRow(
                "Bank details",
                kycConfig['acc_number'] != null,
              ),

              const AppSizedBox(height: 32),
              _buildSectionHeader("PHOTOS", 9),
              _buildReviewRow(
                "Cover photo",
                mediaConfig['cover_url'] != null ? "Set ✓" : "Missing",
              ),

              const AppSizedBox(height: 32),
              _buildTermsNotice(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.slotAvailableBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.celebration_outlined,
            size: 48,
            color: AppColors.primaryDarkGreen,
          ),
          const AppSizedBox(height: 16),
          const AppText(
            text: "You're almost live on CricBook!",
            size: 18,
            weight: FontWeight.w800,
            color: AppColors.primaryDarkGreen,
          ),
          const AppSizedBox(height: 4),
          AppText(
            text: "Review takes 24–48 hours after submission",
            size: 14,
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int step) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              text: title,
              size: 13,
              weight: FontWeight.w800,
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
            GestureDetector(
              onTap: () => _editStep(step),
              child: const AppText(
                text: "Edit",
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.primaryDarkGreen,
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 8),
        Divider(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
          thickness: 1,
        ),
        const AppSizedBox(height: 12),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: AppColors.textSecondaryLight),
          AppText(
            text: value,
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatusRow(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, size: 14, color: AppColors.textSecondaryLight),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.slotAvailableBg
                  : const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AppText(
                  text: isDone ? "Uploaded" : "Pending",
                  size: 12,
                  weight: FontWeight.w700,
                  color: isDone
                      ? AppColors.primaryDarkGreen
                      : const Color(0xFFD97706),
                ),
                if (isDone) ...[
                  const AppSizedBox(width: 4),
                  const Icon(
                    Icons.check,
                    size: 12,
                    color: AppColors.primaryDarkGreen,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slotAvailableBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
        ),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text:
                  "By submitting, you confirm that all information is accurate and you agree to CricBook's ",
            ),
            TextSpan(
              text: "Venue Partner Terms",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkGreen,
              ),
            ),
            TextSpan(text: "."),
          ],
        ),
      ),
    );
  }
}
