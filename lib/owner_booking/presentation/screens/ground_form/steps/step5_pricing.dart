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
  TextEditingController? _morningCtrl;
  TextEditingController? _afternoonCtrl;
  TextEditingController? _eveningCtrl;
  TextEditingController? _nightCtrl;
  TextEditingController? _weekendMorningCtrl;
  TextEditingController? _weekendAfternoonCtrl;
  TextEditingController? _weekendEveningCtrl;
  TextEditingController? _weekendNightCtrl;
  int _selectedDayPeriodTab = 0; // 0 = Weekday, 1 = Weekend
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final p = context.read<GroundFormCubit>().data.pricingConfig;
    _weekdayCtrl = TextEditingController(text: (p['weekday'] ?? 600).toString());
    _weekendCtrl = TextEditingController(text: (p['weekend'] ?? 800).toString());
    _morningCtrl = TextEditingController(
      text: (p['morning'] != null && p['morning']! > 0) ? p['morning'].toString() : '',
    );
    _afternoonCtrl = TextEditingController(
      text: (p['afternoon'] != null && p['afternoon']! > 0) ? p['afternoon'].toString() : '',
    );
    _eveningCtrl = TextEditingController(
      text: (p['evening'] != null && p['evening']! > 0) ? p['evening'].toString() : '',
    );
    _nightCtrl = TextEditingController(
      text: (p['night'] != null && p['night']! > 0) ? p['night'].toString() : '',
    );
    _weekendMorningCtrl = TextEditingController(
      text: (p['weekend_morning'] != null && p['weekend_morning']! > 0) ? p['weekend_morning'].toString() : '',
    );
    _weekendAfternoonCtrl = TextEditingController(
      text: (p['weekend_afternoon'] != null && p['weekend_afternoon']! > 0) ? p['weekend_afternoon'].toString() : '',
    );
    _weekendEveningCtrl = TextEditingController(
      text: (p['weekend_evening'] != null && p['weekend_evening']! > 0) ? p['weekend_evening'].toString() : '',
    );
    _weekendNightCtrl = TextEditingController(
      text: (p['weekend_night'] != null && p['weekend_night']! > 0) ? p['weekend_night'].toString() : '',
    );
    _initialized = true;
  }

  @override
  void dispose() {
    _weekdayCtrl?.dispose();
    _weekendCtrl?.dispose();
    _morningCtrl?.dispose();
    _afternoonCtrl?.dispose();
    _eveningCtrl?.dispose();
    _nightCtrl?.dispose();
    _weekendMorningCtrl?.dispose();
    _weekendAfternoonCtrl?.dispose();
    _weekendEveningCtrl?.dispose();
    _weekendNightCtrl?.dispose();
    super.dispose();
  }

  int _val(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  int? _optionalVal(TextEditingController? c) {
    if (c == null) return null;
    final parsed = int.tryParse(c.text.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  void _onNext() {
    if (!_initialized) return;
    final cubit = context.read<GroundFormCubit>();
    final pricing = {
      'weekday': _val(_weekdayCtrl!, 600),
      'weekend': _val(_weekendCtrl!, 800),
      'morning': _optionalVal(_morningCtrl) ?? 0,
      'afternoon': _optionalVal(_afternoonCtrl) ?? 0,
      'evening': _optionalVal(_eveningCtrl) ?? 0,
      'night': _optionalVal(_nightCtrl) ?? 0,
      'weekend_morning': _optionalVal(_weekendMorningCtrl) ?? 0,
      'weekend_afternoon': _optionalVal(_weekendAfternoonCtrl) ?? 0,
      'weekend_evening': _optionalVal(_weekendEveningCtrl) ?? 0,
      'weekend_night': _optionalVal(_weekendNightCtrl) ?? 0,
    };
    cubit.updateData(cubit.data.copyWith(pricingConfig: pricing));
    cubit.goToStep(4);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return GroundFormLayout(
        isEdit: widget.isEdit,
        currentStep: 3,
        title: 'Pricing',
        subtitle: 'Set rates per 1-hour slot for this ground',
        onNext: _onNext,
        onBack: () => context.read<GroundFormCubit>().goToStep(2),
        child: const SizedBox.shrink(),
      );
    }
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 3,
      title: 'Pricing',
      subtitle: 'Set rates per 1-hour slot for this ground',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBox(
            'Set your base weekday and weekend rates. You can also specify different rates for morning, afternoon, evening, and night slots.',
          ),
          const SizedBox(height: AppSizes.xxl),
          _sectionHeader('BASE DAY RATES'),
          _basePricingTable(),
          const SizedBox(height: AppSizes.xl),
          _sectionHeader('TIME-OF-DAY RATES (OPTIONAL)'),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: AppText(
              text: 'Custom rates for specific time intervals. Leave empty to apply the base rate.',
              size: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          _timeOfDayPricingTable(),
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
                _previewRow('Weekday base slot', _weekdayCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _previewRow('Weekend base slot', _weekendCtrl!),
                const SizedBox(height: AppSizes.md),
                _previewSubtitle('WEEKDAY SLOTS'),
                const SizedBox(height: AppSizes.xs),
                _periodPreviewRow('Morning (06:00 – 12:00)', _morningCtrl!, _weekdayCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Afternoon (12:00 – 16:00)', _afternoonCtrl!, _weekdayCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Evening (16:00 – 20:00)', _eveningCtrl!, _weekdayCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Night (20:00 – 06:00)', _nightCtrl!, _weekdayCtrl!),
                const SizedBox(height: AppSizes.md),
                _previewSubtitle('WEEKEND SLOTS'),
                const SizedBox(height: AppSizes.xs),
                _periodPreviewRow('Morning (06:00 – 12:00)', _weekendMorningCtrl!, _weekendCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Afternoon (12:00 – 16:00)', _weekendAfternoonCtrl!, _weekendCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Evening (16:00 – 20:00)', _weekendEveningCtrl!, _weekendCtrl!),
                const SizedBox(height: AppSizes.xxs),
                _periodPreviewRow('Night (20:00 – 06:00)', _weekendNightCtrl!, _weekendCtrl!),
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

  Widget _basePricingTable() {
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

  Widget _dayTypeTabBar() {
    final hasWeekdayCustom = _optionalVal(_morningCtrl) != null ||
        _optionalVal(_afternoonCtrl) != null ||
        _optionalVal(_eveningCtrl) != null ||
        _optionalVal(_nightCtrl) != null;
    final hasWeekendCustom = _optionalVal(_weekendMorningCtrl) != null ||
        _optionalVal(_weekendAfternoonCtrl) != null ||
        _optionalVal(_weekendEveningCtrl) != null ||
        _optionalVal(_weekendNightCtrl) != null;

    final weekdayBase = _val(_weekdayCtrl!, 600);
    final weekendBase = _val(_weekendCtrl!, 800);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'Weekday (Mon \u2013 Fri)',
              subtitle: 'Base: \u20B9$weekdayBase',
              icon: Icons.calendar_today_outlined,
              isSelected: _selectedDayPeriodTab == 0,
              hasBadge: hasWeekdayCustom,
              activeColor: AppColors.primaryDarkGreen,
              onTap: () => setState(() => _selectedDayPeriodTab = 0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabButton(
              title: 'Weekend (Sat \u2013 Sun)',
              subtitle: 'Base: \u20B9$weekendBase',
              icon: Icons.wb_sunny_outlined,
              isSelected: _selectedDayPeriodTab == 1,
              hasBadge: hasWeekendCustom,
              activeColor: const Color(0xFFE65100),
              onTap: () => setState(() => _selectedDayPeriodTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool hasBadge,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm, horizontal: AppSizes.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? activeColor : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSizes.xxs),
                Flexible(
                  child: AppText(
                    text: title,
                    size: 12,
                    weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? activeColor : AppColors.textSecondaryLight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasBadge) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            AppText(
              text: subtitle,
              size: 11,
              weight: FontWeight.w600,
              color: isSelected
                  ? activeColor.withValues(alpha: 0.8)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeOfDayPricingTable() {
    final isWeekend = _selectedDayPeriodTab == 1;
    final baseRate = isWeekend ? _val(_weekendCtrl!, 800) : _val(_weekdayCtrl!, 600);

    return Column(
      children: [
        _dayTypeTabBar(),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isWeekend ? const Color(0xFFFFCC80) : AppColors.borderLight,
            ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: isWeekend ? const Color(0xFFFFF9E6) : const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusLg),
                    topRight: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: isWeekend ? 'WEEKEND TIME PERIOD' : 'WEEKDAY TIME PERIOD',
                      size: 11,
                      weight: FontWeight.w800,
                      color: isWeekend ? const Color(0xFFE65100) : AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                    AppText(
                      text: 'RATE / HR',
                      size: 11,
                      weight: FontWeight.w800,
                      color: isWeekend ? const Color(0xFFE65100) : AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ],
                ),
              ),
              _periodPricingRow(
                key: ValueKey('morning-$isWeekend'),
                title: 'Morning',
                subtitle: '06:00 AM – 12:00 PM',
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFB300),
                ctrl: isWeekend ? _weekendMorningCtrl! : _morningCtrl!,
                baseRate: baseRate,
              ),
              _periodPricingRow(
                key: ValueKey('afternoon-$isWeekend'),
                title: 'Afternoon',
                subtitle: '12:00 PM – 04:00 PM',
                icon: Icons.wb_cloudy_rounded,
                iconColor: const Color(0xFFFF7043),
                ctrl: isWeekend ? _weekendAfternoonCtrl! : _afternoonCtrl!,
                baseRate: baseRate,
              ),
              _periodPricingRow(
                key: ValueKey('evening-$isWeekend'),
                title: 'Evening',
                subtitle: '04:00 PM – 08:00 PM',
                icon: Icons.wb_twilight_rounded,
                iconColor: const Color(0xFFE65100),
                ctrl: isWeekend ? _weekendEveningCtrl! : _eveningCtrl!,
                baseRate: baseRate,
              ),
              _periodPricingRow(
                key: ValueKey('night-$isWeekend'),
                title: 'Night',
                subtitle: '08:00 PM – 06:00 AM',
                icon: Icons.nights_stay_rounded,
                iconColor: const Color(0xFF5C6BC0),
                ctrl: isWeekend ? _weekendNightCtrl! : _nightCtrl!,
                baseRate: baseRate,
              ),
            ],
          ),
        ),
      ],
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

  Widget _previewSubtitle(String text) {
    return AppText(
      text: text,
      size: 11,
      weight: FontWeight.w800,
      color: AppColors.primaryDarkGreen.withValues(alpha: 0.7),
      letterSpacing: 0.5,
    );
  }

  Widget _periodPricingRow({
    Key? key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TextEditingController ctrl,
    required int baseRate,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: title,
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                    AppText(
                      text: subtitle,
                      size: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkGreen,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    hintText: 'Base ($baseRate)',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDarkGreen,
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

  Widget _periodPreviewRow(
    String label,
    TextEditingController periodCtrl,
    TextEditingController baseCtrl,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([periodCtrl, baseCtrl]),
      builder: (_, _) {
        final customVal = int.tryParse(periodCtrl.text.trim());
        final isCustom = customVal != null && customVal > 0;
        final displayVal = isCustom ? customVal : _val(baseCtrl, 0);

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
                color: isCustom ? const Color(0xFFE8F5E9) : AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: isCustom
                    ? Border.all(color: AppColors.primaryDarkGreen.withValues(alpha: 0.3))
                    : null,
              ),
              child: AppText(
                text: '\u20B9$displayVal / hr${isCustom ? '' : ' (base)'}',
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
