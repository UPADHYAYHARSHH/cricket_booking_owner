import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

const List<String> _kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _kDurations = ['30 min', '1 Hour', '1.5 Hours', '2 Hours'];
const List<String> _kAdvance = ['Same day', '3 days', '7 days', '15 days', '30 days'];

class Step4Schedule extends StatefulWidget {
  final bool isEdit;
  const Step4Schedule({super.key, required this.isEdit});

  @override
  State<Step4Schedule> createState() => _Step4ScheduleState();
}

class _Step4ScheduleState extends State<Step4Schedule> {
  List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 23, minute: 0);
  String _slotDuration = '1 Hour';
  String _advanceLimit = '7 days';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final data = context.read<GroundFormCubit>().data;
    _selectedDays = List.from(data.operatingDays);
    _openTime = _parseHHmm(data.openingTime) ?? const TimeOfDay(hour: 6, minute: 0);
    _closeTime = _parseHHmm(data.closingTime) ?? const TimeOfDay(hour: 23, minute: 0);
    _slotDuration = data.slotDuration;
    _advanceLimit = data.advanceBookingLimit;
    _initialized = true;
  }

  TimeOfDay? _parseHHmm(String s) {
    try {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatTD(TimeOfDay t) {
    final now = DateTime.now();
    return DateFormat.jm().format(DateTime(now.year, now.month, now.day, t.hour, t.minute));
  }

  String _toHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(TimeOfDay initial, ValueChanged<TimeOfDay> onPick) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPick(picked);
  }

  void _onNext() {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one operating day')),
      );
      return;
    }
    if (_openTime.hour >= _closeTime.hour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Closing time must be after opening time')),
      );
      return;
    }
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(
      operatingDays: List.from(_selectedDays),
      openingTime: _toHHmm(_openTime),
      closingTime: _toHHmm(_closeTime),
      slotDuration: _slotDuration,
      advanceBookingLimit: _advanceLimit,
    ));
    cubit.goToStep(4);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 3,
      title: 'Schedule',
      subtitle: 'Set operating hours and booking window',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('OPERATING DAYS'),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: _kDays.map((day) {
              final sel = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() =>
                    sel ? _selectedDays.remove(day) : _selectedDays.add(day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryDarkGreen,
                              Color(0xFF066B3E),
                            ],
                          )
                        : null,
                    color: sel ? null : AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: sel ? AppColors.primaryDarkGreen : AppColors.borderLight,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: AppText(
                    text: day,
                    size: 14,
                    weight: FontWeight.w700,
                    color: sel ? AppColors.white : AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.xxl + AppSizes.sm),
          _sectionHeader('OPERATING HOURS'),
          Row(
            children: [
              Expanded(
                child: _timeTile(
                  label: 'OPENING TIME',
                  value: _formatTD(_openTime),
                  onTap: () => _pickTime(_openTime, (t) => setState(() => _openTime = t)),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _timeTile(
                  label: 'CLOSING TIME',
                  value: _formatTD(_closeTime),
                  onTap: () => _pickTime(_closeTime, (t) => setState(() => _closeTime = t)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Builder(builder: (_) {
            final hrs = _closeTime.hour - _openTime.hour;
            if (hrs <= 0) return const SizedBox.shrink();
            return Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.primaryDarkGreen.withValues(alpha: 0.7)),
                const SizedBox(width: AppSizes.xs),
                AppText(
                  text: '${hrs}h window \u2192 ${_formatTD(_openTime)} to ${_formatTD(_closeTime)}',
                  size: 12,
                  color: AppColors.primaryDarkGreen,
                  weight: FontWeight.w600,
                ),
              ],
            );
          }),
          const SizedBox(height: AppSizes.xxl + AppSizes.sm),
          _sectionHeader('SLOT DURATION *'),
          _chips(_kDurations, _slotDuration, (v) => setState(() => _slotDuration = v)),
          const SizedBox(height: AppSizes.sm),
          _helperText('Players can book multiple consecutive slots'),
          const SizedBox(height: AppSizes.xxl + AppSizes.sm),
          _sectionHeader('ADVANCE BOOKING LIMIT'),
          _chips(_kAdvance, _advanceLimit, (v) => setState(() => _advanceLimit = v)),
          const SizedBox(height: AppSizes.sm),
          _helperText('How far in advance players can book a slot'),
          if (widget.isEdit) ...[
            const SizedBox(height: AppSizes.xl),
            _warningBanner(
              'Changing operating hours will regenerate future available slots. Already-booked slots are not affected.',
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _helperText(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 12,
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: AppText(
              text: text,
              size: 11,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      );

  Widget _timeTile({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(text: value, size: 16, weight: FontWeight.w700),
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.slotAvailableBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: AppSizes.iconSm,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips(List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: options.map((opt) {
        final isSel = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              gradient: isSel
                  ? const LinearGradient(
                      colors: [
                        AppColors.primaryDarkGreen,
                        Color(0xFF066B3E),
                      ],
                    )
                  : null,
              color: isSel ? null : AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              border: Border.all(
                color: isSel ? AppColors.primaryDarkGreen : AppColors.borderLight,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: opt,
              size: 13,
              weight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppColors.white : AppColors.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _warningBanner(String text) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.accentOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.accentOrange,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: AppText(
                text: text,
                size: 12,
                color: const Color(0xFF795548),
              ),
            ),
          ],
        ),
      );
}
