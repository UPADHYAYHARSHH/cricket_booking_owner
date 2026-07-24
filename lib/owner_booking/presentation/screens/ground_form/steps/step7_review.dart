import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_data.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_state.dart';

class Step7Review extends StatelessWidget {
  final bool isEdit;
  const Step7Review({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroundFormCubit, GroundFormState>(
      listener: (context, state) {
        if (state is GroundFormError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Save failed'),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<GroundFormCubit>();
        final data = cubit.data;
        final isSaving = state is GroundFormSaving;

        return GroundFormLayout(
          isEdit: isEdit,
          currentStep: 5,
          title: 'Review & Save',
          subtitle: isEdit
              ? 'Confirm your changes before saving'
              : 'Verify details before adding this ground',
          onNext: () => cubit.save(),
          onBack: () => cubit.goToStep(3),
          isLoading: isSaving,
          nextLabel: isEdit ? 'Save Changes' : 'Add Ground',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _banner(isEdit),
              const SizedBox(height: AppSizes.xxl + AppSizes.sm),

              _section(
                title: 'SPORT',
                step: 1,
                context: context,
                child: data.category.isEmpty
                    ? _missing('No sport selected')
                    : _row(
                        Icons.category_outlined,
                        'Sport',
                        _sportName(data.category),
                      ),
              ),

              _section(
                title: 'SCHEDULE',
                step: 2,
                context: context,
                child: Column(
                  children: [
                    _row(
                      Icons.calendar_today_outlined,
                      'Operating days',
                      data.operatingDays.join(', '),
                    ),
                    _row(
                      Icons.schedule,
                      'Hours',
                      '${data.openingTime} \u2013 ${data.closingTime}',
                    ),
                    _row(
                      Icons.timer_outlined,
                      'Slot duration',
                      data.slotDuration,
                    ),
                    _row(
                      Icons.event_outlined,
                      'Advance booking',
                      data.advanceBookingLimit,
                    ),
                  ],
                ),
              ),

              _section(
                title: 'PRICING',
                step: 3,
                context: context,
                child: Column(
                  children: [
                    _row(
                      Icons.monetization_on_outlined,
                      'Weekday base',
                      '\u20B9${data.pricingConfig['weekday'] ?? 0}/hr',
                    ),
                    _row(
                      Icons.monetization_on_outlined,
                      'Weekend base',
                      '\u20B9${data.pricingConfig['weekend'] ?? 0}/hr',
                    ),
                    if ((data.pricingConfig['morning'] ?? 0) > 0)
                      _row(
                        Icons.wb_sunny_outlined,
                        'Morning peak',
                        '\u20B9${data.pricingConfig['morning']}/hr',
                      ),
                    if ((data.pricingConfig['evening'] ?? 0) > 0)
                      _row(
                        Icons.wb_twilight_outlined,
                        'Evening peak',
                        '\u20B9${data.pricingConfig['evening']}/hr',
                      ),
                    if ((data.pricingConfig['night'] ?? 0) > 0)
                      _row(
                        Icons.nightlight_outlined,
                        'Night',
                        '\u20B9${data.pricingConfig['night']}/hr',
                      ),
                  ],
                ),
              ),

              // Photos section hidden per request.
              if (!isEdit && !_isValid(data)) ...[
                const SizedBox(height: AppSizes.xl),
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFFF8E1).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: AppColors.accentOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.accentOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: AppText(
                          text: _validationMessage(data),
                          size: 13,
                          color: const Color(0xFF795548),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _isValid(GroundFormData d) =>
      d.category.isNotEmpty && d.locationId.isNotEmpty;

  String _validationMessage(GroundFormData d) {
    final issues = <String>[];
    if (d.category.isEmpty) issues.add('sport not selected');
    if (d.locationId.isEmpty) issues.add('location missing');
    return 'Please fix: ${issues.join(', ')}';
  }

  Widget _banner(bool isEdit) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.xl),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.slotAvailableBg, AppColors.white],
      ),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDarkGreen, Color(0xFF066B3E)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isEdit ? Icons.edit_note_rounded : Icons.check_circle_outline,
            size: 32,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        AppText(
          text: isEdit
              ? 'Almost done \u2014 review your edits'
              : "You're ready to go live!",
          size: 17,
          weight: FontWeight.w800,
          color: AppColors.primaryDarkGreen,
        ),
        const SizedBox(height: AppSizes.xs),
        AppText(
          text: isEdit
              ? 'Changes are saved immediately.'
              : 'Our team reviews new grounds within 24\u201348 hours.',
          size: 13,
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.6),
        ),
      ],
    ),
  );

  Widget _section({
    required String title,
    required int step,
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  AppText(
                    text: title,
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.primaryDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.read<GroundFormCubit>().goToStep(step),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slotAvailableBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  ),
                  child: const AppText(
                    text: 'Edit',
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          flex: 2,
          child: AppText(
            text: label,
            size: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: AppSizes.xs),
        Expanded(
          flex: 3,
          child: AppText(
            text: value,
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    ),
  );

  Widget _missing(String text) => Row(
    children: [
      Icon(
        Icons.info_outline,
        size: 14,
        color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
      ),
      const SizedBox(width: AppSizes.sm),
      AppText(text: text, size: 13, color: AppColors.textSecondaryLight),
    ],
  );

  String _sportName(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}
