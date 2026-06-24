import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
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
            spacing: 8,
            runSpacing: 8,
            children: _kDays.map((day) {
              final sel = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() =>
                    sel ? _selectedDays.remove(day) : _selectedDays.add(day)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryDarkGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel
                            ? AppColors.primaryDarkGreen
                            : Colors.grey.shade300),
                  ),
                  child: AppText(
                    text: day,
                    size: 14,
                    weight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
          ),
          const AppSizedBox(height: 28),
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
              const AppSizedBox(width: 14),
              Expanded(
                child: _timeTile(
                  label: 'CLOSING TIME',
                  value: _formatTD(_closeTime),
                  onTap: () => _pickTime(_closeTime, (t) => setState(() => _closeTime = t)),
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 8),
          Builder(builder: (_) {
            final hrs = _closeTime.hour - _openTime.hour;
            if (hrs <= 0) return const SizedBox.shrink();
            return AppText(
              text: '${hrs}h window → ${_formatTD(_openTime)} to ${_formatTD(_closeTime)}',
              size: 12,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.w600,
            );
          }),
          const AppSizedBox(height: 28),
          _label('SLOT DURATION *'),
          _chips(_kDurations, _slotDuration,
              (v) => setState(() => _slotDuration = v)),
          const AppSizedBox(height: 6),
          const AppText(
            text: 'Players can book multiple consecutive slots',
            size: 11,
            color: AppColors.textSecondaryLight,
          ),
          const AppSizedBox(height: 28),
          _label('ADVANCE BOOKING LIMIT'),
          _chips(_kAdvance, _advanceLimit,
              (v) => setState(() => _advanceLimit = v)),
          const AppSizedBox(height: 6),
          const AppText(
            text: 'How far in advance players can book a slot',
            size: 11,
            color: AppColors.textSecondaryLight,
          ),
          if (widget.isEdit) ...[
            const AppSizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.accentOrange),
                  const AppSizedBox(width: 8),
                  const Expanded(
                    child: AppText(
                      text:
                          'Changing operating hours will regenerate future available slots. Already-booked slots are not affected.',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppText(
          text: text,
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
        ),
      );

  Widget _timeTile({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F4).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(text: value, size: 16, weight: FontWeight.w700),
                const Icon(Icons.access_time, size: 20, color: AppColors.primaryDarkGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips(List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSel = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSel ? AppColors.primaryDarkGreen : Colors.grey.shade200,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: opt,
              size: 13,
              weight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }
}
