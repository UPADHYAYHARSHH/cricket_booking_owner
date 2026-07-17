import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

class Step5Pricing extends StatefulWidget {
  final bool isEdit;
  const Step5Pricing({super.key, required this.isEdit});

  @override
  State<Step5Pricing> createState() => _Step5PricingState();
}

class _Step5PricingState extends State<Step5Pricing> {
  TextEditingController? _weekdayCtrl;
  TextEditingController? _weekendCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final p = context.read<GroundFormCubit>().data.pricingConfig;
    _weekdayCtrl = TextEditingController(text: (p['weekday'] ?? 600).toString());
    _weekendCtrl = TextEditingController(text: (p['weekend'] ?? 800).toString());
    _initialized = true;
  }

  @override
  void dispose() {
    _weekdayCtrl?.dispose();
    _weekendCtrl?.dispose();
    super.dispose();
  }

  int _val(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  void _onNext() {
    if (!_initialized) return;
    final cubit = context.read<GroundFormCubit>();
    final pricing = {
      'weekday': _val(_weekdayCtrl!, 600),
      'weekend': _val(_weekendCtrl!, 800),
    };
    cubit.updateData(cubit.data.copyWith(pricingConfig: pricing));
    cubit.goToStep(5);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return GroundFormLayout(
        isEdit: widget.isEdit,
        currentStep: 4,
        title: 'Pricing',
        subtitle: 'Set rates per 1-hour slot for this ground',
        onNext: _onNext,
        onBack: () => context.read<GroundFormCubit>().goToStep(3),
        child: const SizedBox.shrink(),
      );
    }
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 4,
      title: 'Pricing',
      subtitle: 'Set rates per 1-hour slot for this ground',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBox(
            'Set your weekday and weekend rates. Players will be charged based on the day of their booking.',
          ),
          const SizedBox(height: AppSizes.xxl + AppSizes.sm),
          _sectionHeader('SLOT RATES'),
          _pricingTable(),
          const SizedBox(height: AppSizes.lg),
          // Live preview
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.slotAvailableBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    const AppText(
                      text: 'PRICE PREVIEW',
                      size: 12,
                      weight: FontWeight.w800,
                      color: AppColors.primaryDarkGreen,
                      letterSpacing: 0.5,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _previewRow('Mon \u2013 Fri slot', _weekdayCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _previewRow('Sat \u2013 Sun slot', _weekendCtrl!),
              ],
            ),
          ),
          if (widget.isEdit) ...[
            const SizedBox(height: AppSizes.xl),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.accentOrange,
                  ),
                  AppSizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      text: 'Pricing updates apply to new slots only. Already-booked slots retain the price agreed at booking time.',
                      size: 12,
                      color: Color(0xFF795548),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pricingTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'DAY TYPE',
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
                AppText(
                  text: 'RATE / HR',
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
              ],
            ),
          ),
          _pricingRow('Weekday (Mon \u2013 Fri)', _weekdayCtrl!, isWeekend: false),
          _pricingRow('Weekend (Sat \u2013 Sun)', _weekendCtrl!, isWeekend: true),
        ],
      ),
    );
  }

  Widget _pricingRow(String label, TextEditingController ctrl, {required bool isWeekend}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: isWeekend ? const Color(0xFFFFF9E6) : AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (isWeekend)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.xs),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        size: 14,
                        color: Color(0xFFFBC02D),
                      ),
                    ),
                  ),
                AppText(
                  text: label,
                  size: 13,
                  weight: isWeekend ? FontWeight.w700 : FontWeight.w500,
                  color: isWeekend ? const Color(0xFFF57F17) : AppColors.textPrimaryLight,
                ),
              ],
            ),
          ),
          Row(
            children: [
              AppText(
                text: '\u20B9 ',
                size: 15,
                color: AppColors.textSecondaryLight,
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isWeekend
                        ? const Color(0xFFF57F17)
                        : AppColors.primaryDarkGreen,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: BorderSide(
                        color: isWeekend
                            ? const Color(0xFFFBC02D)
                            : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: BorderSide(
                        color: isWeekend
                            ? const Color(0xFFFBC02D).withValues(alpha: 0.5)
                            : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: BorderSide(
                        color: isWeekend
                            ? const Color(0xFFFBC02D)
                            : AppColors.primaryDarkGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, TextEditingController ctrl) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, _, _) {
        final val = _val(ctrl, 0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              text: label,
              size: 13,
              color: AppColors.textSecondaryLight,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: AppText(
                text: '\u20B9$val / hr',
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.primaryDarkGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF5FB),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.chartBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: AppColors.chartBlue.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: AppText(
                text: text,
                size: 12,
                color: AppColors.chartBlue.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: Row(
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
              text: t,
              size: 13,
              weight: FontWeight.w800,
              color: AppColors.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ],
        ),
      );
}
