import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';

class SlotConfigScreen extends StatefulWidget {
  const SlotConfigScreen({super.key});

  @override
  State<SlotConfigScreen> createState() => _SlotConfigScreenState();
}

class _SlotConfigScreenState extends State<SlotConfigScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 23, minute: 0);

  String _slotDuration = '1 Hour';
  final List<String> _durations = ['30 min', '45 min', '1 Hour', '1.5 Hours', '2 Hours'];

  TimeOfDay _morningPeakStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _morningPeakEnd = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _eveningPeakStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _eveningPeakEnd = const TimeOfDay(hour: 23, minute: 0);

  String _advanceBookingLimit = '7 days';
  final List<String> _advanceOptions = ['Same day', '7 days', '15 days', '30 days'];

  String _cancellationWindow = '2 hours';
  final List<String> _cancelOptions = ['1 hour', '2 hours', '4 hours', '24 hours'];

  String _minBookingDuration = '1 Slot (1 hr)';
  final List<String> _minDurationOptions = ['1 Slot (1 hr)', '2 Slots (2 hrs)'];

  bool _allowPartialBlocking = true;
  bool _maintenanceSlot = false;

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['slot_config'] != null) {
        final config = data['slot_config'];
        setState(() {
          if (config['operating_days'] != null) {
            _selectedDays.clear();
            _selectedDays.addAll(List<String>.from(config['operating_days']));
          }
          _openingTime = _parseTime(config['opening_time']) ?? _openingTime;
          _closingTime = _parseTime(config['closing_time']) ?? _closingTime;
          _slotDuration = config['slot_duration'] ?? _slotDuration;
          
          _morningPeakStart = _parseTime(config['morning_peak_start']) ?? _morningPeakStart;
          _morningPeakEnd = _parseTime(config['morning_peak_end']) ?? _morningPeakEnd;
          _eveningPeakStart = _parseTime(config['evening_peak_start']) ?? _eveningPeakStart;
          _eveningPeakEnd = _parseTime(config['evening_peak_end']) ?? _eveningPeakEnd;

          _advanceBookingLimit = config['advance_booking_limit'] ?? _advanceBookingLimit;
          _cancellationWindow = config['cancellation_window'] ?? _cancellationWindow;
          _minBookingDuration = config['min_booking_duration'] ?? _minBookingDuration;
          _allowPartialBlocking = config['allow_partial_blocking'] ?? _allowPartialBlocking;
          _maintenanceSlot = config['maintenance_slot'] ?? _maintenanceSlot;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final format = DateFormat.jm(); // 6:00 AM
      final dt = format.parse(timeStr);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initial, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  void _onSave() {
    final config = {
      'operating_days': _selectedDays,
      'opening_time': _formatTime(_openingTime),
      'closing_time': _formatTime(_closingTime),
      'slot_duration': _slotDuration,
      'morning_peak_start': _formatTime(_morningPeakStart),
      'morning_peak_end': _formatTime(_morningPeakEnd),
      'evening_peak_start': _formatTime(_eveningPeakStart),
      'evening_peak_end': _formatTime(_eveningPeakEnd),
      'advance_booking_limit': _advanceBookingLimit,
      'cancellation_window': _cancellationWindow,
      'min_booking_duration': _minBookingDuration,
      'allow_partial_blocking': _allowPartialBlocking,
      'maintenance_slot': _maintenanceSlot,
    };

    context.read<AuthCubit>().saveSlotConfig(slotConfig: config);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return OnboardingLayout(
            currentStep: 6,
            title: "Slot Configuration",
            subtitle: "Set up your operating hours & slot structure",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("OPERATING DAYS"),
                _buildDaysSelector(),
                const AppSizedBox(height: 32),
                
                _buildSectionHeader("OPERATING HOURS"),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePickerField(
                        label: "OPENING TIME *",
                        time: _openingTime,
                        onTap: () => _selectTime(context, _openingTime, (t) => setState(() => _openingTime = t)),
                      ),
                    ),
                    const AppSizedBox(width: 16),
                    Expanded(
                      child: _buildTimePickerField(
                        label: "CLOSING TIME *",
                        time: _closingTime,
                        onTap: () => _selectTime(context, _closingTime, (t) => setState(() => _closingTime = t)),
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: 24),
                
                _buildLabel("SLOT DURATION *"),
                _buildChoiceChips(
                  options: _durations,
                  selected: _slotDuration,
                  onSelected: (v) => setState(() => _slotDuration = v),
                ),
                const AppSizedBox(height: 8),
                const AppText(text: "Players can book multiple consecutive slots", size: 12, color: AppColors.textSecondaryLight),
                
                const AppSizedBox(height: 32),
                _buildSectionHeader("PEAK HOURS DEFINITION"),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F4).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeakTimeRow(
                        label: "MORNING PEAK",
                        startTime: _morningPeakStart,
                        endTime: _morningPeakEnd,
                        onStartTap: () => _selectTime(context, _morningPeakStart, (t) => setState(() => _morningPeakStart = t)),
                        onEndTap: () => _selectTime(context, _morningPeakEnd, (t) => setState(() => _morningPeakEnd = t)),
                      ),
                      const AppSizedBox(height: 20),
                      _buildPeakTimeRow(
                        label: "EVENING PEAK",
                        startTime: _eveningPeakStart,
                        endTime: _eveningPeakEnd,
                        onStartTap: () => _selectTime(context, _eveningPeakStart, (t) => setState(() => _eveningPeakStart = t)),
                        onEndTap: () => _selectTime(context, _eveningPeakEnd, (t) => setState(() => _eveningPeakEnd = t)),
                      ),
                    ],
                  ),
                ),

                const AppSizedBox(height: 32),
                _buildLabel("ADVANCE BOOKING LIMIT"),
                _buildChoiceChips(
                  options: _advanceOptions,
                  selected: _advanceBookingLimit,
                  onSelected: (v) => setState(() => _advanceBookingLimit = v),
                ),

                const AppSizedBox(height: 32),
                _buildLabel("CANCELLATION WINDOW"),
                _buildChoiceChips(
                  options: _cancelOptions,
                  selected: _cancellationWindow,
                  onSelected: (v) => setState(() => _cancellationWindow = v),
                ),
                const AppSizedBox(height: 8),
                const AppText(text: "Free cancellation if done before this window", size: 12, color: AppColors.textSecondaryLight),

                const AppSizedBox(height: 32),
                _buildLabel("MINIMUM BOOKING DURATION"),
                _buildChoiceChips(
                  options: _minDurationOptions,
                  selected: _minBookingDuration,
                  onSelected: (v) => setState(() => _minBookingDuration = v),
                ),

                const AppSizedBox(height: 32),
                _buildLabel("SLOT BLOCKING"),
                _buildSwitchTile(
                  "Allow partial slot blocking",
                  "Block specific courts at certain times",
                  _allowPartialBlocking,
                  (v) => setState(() => _allowPartialBlocking = v),
                ),
                _buildSwitchTile(
                  "Maintenance slot (weekly)",
                  "Auto-block for ground maintenance",
                  _maintenanceSlot,
                  (v) => setState(() => _maintenanceSlot = v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppText(
        text: title,
        size: 13,
        weight: FontWeight.w800,
        color: AppColors.textSecondaryLight.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppText(
        text: label,
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _days.map((day) {
        final isSelected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300),
            ),
            child: AppText(
              text: day,
              size: 14,
              weight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePickerField({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F4).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(text: _formatTime(time), size: 16, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
                const Icon(Icons.access_time, size: 20, color: AppColors.primaryDarkGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeakTimeRow({required String label, required TimeOfDay startTime, required TimeOfDay endTime, required VoidCallback onStartTap, required VoidCallback onEndTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onStartTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: AppText(text: _formatTime(startTime), size: 15, weight: FontWeight.w600),
                ),
              ),
            ),
            const AppSizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onEndTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: AppText(text: _formatTime(endTime), size: 15, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: option,
              size: 13,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: AppText(text: title, size: 15, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
        subtitle: AppText(text: subtitle, size: 12, color: AppColors.textSecondaryLight),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryLightGreen,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade200,
      ),
    );
  }
}
