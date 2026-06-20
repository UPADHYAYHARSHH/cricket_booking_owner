import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
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
    cubit.goToStep(6);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return GroundFormLayout(
        isEdit: widget.isEdit,
        currentStep: 5,
        title: 'Pricing',
        subtitle: 'Set rates per 1-hour slot for this ground',
        onNext: _onNext,
        onBack: () => context.read<GroundFormCubit>().goToStep(4),
        child: const SizedBox.shrink(),
      );
    }
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 5,
      title: 'Pricing',
      subtitle: 'Set rates per 1-hour slot for this ground',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBox('Set your weekday and weekend rates. Players will be charged based on the day of their booking.'),
          const AppSizedBox(height: 28),
          _sectionHeader('SLOT RATES'),
          _pricingTable(),
          const AppSizedBox(height: 16),
          // Live preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'PRICE PREVIEW',
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.primaryDarkGreen,
                  letterSpacing: 0.5,
                ),
                const AppSizedBox(height: 10),
                _previewRow('Mon – Fri slot', _weekdayCtrl!),
                _previewRow('Sat – Sun slot', _weekendCtrl!),
              ],
            ),
          ),
          if (widget.isEdit) ...[
            const AppSizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 16, color: AppColors.accentOrange),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'DAY TYPE',
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.primaryDarkGreen.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
                AppText(
                  text: 'RATE / HR',
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.primaryDarkGreen.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ],
            ),
          ),
          _pricingRow('Weekday (Mon – Fri)', _weekdayCtrl!, isWeekend: false),
          _pricingRow('Weekend (Sat – Sun)', _weekendCtrl!, isWeekend: true),
        ],
      ),
    );
  }

  Widget _pricingRow(String label, TextEditingController ctrl, {required bool isWeekend}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isWeekend ? const Color(0xFFFFF9E6) : Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (isWeekend)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFFBC02D)),
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
              const AppText(text: '₹ ', size: 15, color: AppColors.textSecondaryLight),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isWeekend ? const Color(0xFFF57F17) : AppColors.primaryDarkGreen,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isWeekend
                            ? const Color(0xFFFBC02D)
                            : AppColors.primaryDarkGreen.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isWeekend
                            ? const Color(0xFFFBC02D).withOpacity(0.5)
                            : AppColors.primaryDarkGreen.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isWeekend ? const Color(0xFFFBC02D) : AppColors.primaryDarkGreen,
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
      builder: (_, __, ___) {
        final val = _val(ctrl, 0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(text: label, size: 13, color: AppColors.textSecondaryLight),
              AppText(
                text: '₹$val / hr',
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.primaryDarkGreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: AppText(text: text, size: 12, color: Colors.blue.shade800),
      );

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppText(
          text: t,
          size: 13,
          weight: FontWeight.w800,
          color: AppColors.textSecondaryLight.withOpacity(0.8),
          letterSpacing: 0.5,
        ),
      );
}
