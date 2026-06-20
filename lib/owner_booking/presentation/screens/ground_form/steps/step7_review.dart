import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
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
          currentStep: 7,
          title: 'Review & Save',
          subtitle: isEdit
              ? 'Confirm your changes before saving'
              : 'Verify details before adding this ground',
          onNext: () => cubit.save(),
          onBack: () => cubit.goToStep(6),
          isLoading: isSaving,
          nextLabel: isEdit ? 'Save Changes' : 'Add Ground',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _banner(isEdit),
              const AppSizedBox(height: 28),

              _section(
                title: 'SPORTS & COURTS',
                step: 1,
                context: context,
                child: data.sportsConfig.isEmpty
                    ? _missing('No sports selected')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.sportsConfig.entries.map((e) {
                          return _row(
                            _sportName(e.key),
                            '${e.value} court${e.value > 1 ? 's' : ''}',
                          );
                        }).toList(),
                      ),
              ),

              _section(
                title: 'BASIC INFO',
                step: 2,
                context: context,
                child: Column(
                  children: [
                    _row('Name', data.name.isEmpty ? '—' : data.name),
                    if (data.description.isNotEmpty)
                      _row(
                        'Description',
                        data.description.length > 60
                            ? '${data.description.substring(0, 57)}…'
                            : data.description,
                      ),
                  ],
                ),
              ),

              _section(
                title: 'LOCATION',
                step: 3,
                context: context,
                child: Column(
                  children: [
                    _row('Address', data.address.isEmpty ? '—' : data.address),
                    _row('City', data.city.isEmpty ? '—' : data.city),
                    if (data.latitude != 0.0 || data.longitude != 0.0)
                      _row('GPS', '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}'),
                  ],
                ),
              ),

              _section(
                title: 'SCHEDULE',
                step: 4,
                context: context,
                child: Column(
                  children: [
                    _row('Operating days', data.operatingDays.join(', ')),
                    _row('Hours', '${data.openingTime} – ${data.closingTime}'),
                    _row('Slot duration', data.slotDuration),
                    _row('Advance booking', data.advanceBookingLimit),
                  ],
                ),
              ),

              _section(
                title: 'PRICING',
                step: 5,
                context: context,
                child: Column(
                  children: [
                    _row('Weekday base', '₹${data.pricingConfig['weekday'] ?? 0}/hr'),
                    _row('Weekend base', '₹${data.pricingConfig['weekend'] ?? 0}/hr'),
                    _row('Morning peak', '₹${data.pricingConfig['morning'] ?? 0}/hr'),
                    _row('Evening peak', '₹${data.pricingConfig['evening'] ?? 0}/hr'),
                    _row('Night', '₹${data.pricingConfig['night'] ?? 0}/hr'),
                  ],
                ),
              ),

              _section(
                title: 'AMENITIES',
                step: 6,
                context: context,
                child: data.amenities.isEmpty
                    ? _missing('None selected yet')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.amenities.map((a) => _chip(a)).toList(),
                      ),
              ),

              if (!isEdit && !_isValid(data)) ...[
                const AppSizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, color: AppColors.accentOrange, size: 18),
                      const AppSizedBox(width: 8),
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
      d.categories.isNotEmpty && d.name.isNotEmpty && d.address.isNotEmpty && d.city.isNotEmpty;

  String _validationMessage(GroundFormData d) {
    final issues = <String>[];
    if (d.categories.isEmpty) issues.add('sports not selected');
    if (d.name.isEmpty) issues.add('ground name missing');
    if (d.address.isEmpty) issues.add('address missing');
    if (d.city.isEmpty) issues.add('city missing');
    return 'Please fix: ${issues.join(', ')}';
  }

  Widget _banner(bool isEdit) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              isEdit ? Icons.edit_note_rounded : Icons.check_circle_outline,
              size: 44,
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 12),
            AppText(
              text: isEdit ? 'Almost done — review your edits' : "You're ready to go live!",
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 4),
            AppText(
              text: isEdit
                  ? 'Changes are saved immediately.'
                  : 'Our team reviews new grounds within 24–48 hours.',
              size: 13,
              color: AppColors.primaryDarkGreen.withOpacity(0.6),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: title,
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.primaryDarkGreen.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
              GestureDetector(
                onTap: () => context.read<GroundFormCubit>().goToStep(step),
                child: const AppText(
                  text: 'Edit',
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
          Divider(
              color: AppColors.primaryDarkGreen.withOpacity(0.1), thickness: 1),
          const AppSizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppText(
                  text: label,
                  size: 13,
                  color: AppColors.textSecondaryLight),
            ),
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

  Widget _missing(String text) =>
      AppText(text: text, size: 13, color: Colors.grey);

  Widget _chip(String id) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.slotAvailableBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        child: AppText(
          text: id.replaceAll('_', ' '),
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.primaryDarkGreen,
        ),
      );

  String _sportName(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}
