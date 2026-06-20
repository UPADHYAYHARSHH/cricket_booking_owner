import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

const List<Map<String, dynamic>> _kSports = [
  {'id': 'box_cricket', 'name': 'Box Cricket', 'subtitle': 'Enclosed cricket arena', 'icon': Icons.sports_cricket},
  {'id': 'football', 'name': 'Football / Futsal', 'subtitle': '5-a-side, 7-a-side', 'icon': Icons.sports_soccer},
  {'id': 'badminton', 'name': 'Badminton', 'subtitle': 'Single / double court', 'icon': Icons.sports_tennis},
  {'id': 'volleyball', 'name': 'Volleyball', 'subtitle': 'Indoor / outdoor', 'icon': Icons.sports_volleyball},
  {'id': 'pickleball', 'name': 'Pickleball', 'subtitle': 'Paddle sport', 'icon': Icons.sports_tennis},
  {'id': 'tennis', 'name': 'Tennis', 'subtitle': 'Hard / clay / grass', 'icon': Icons.sports_tennis},
  {'id': 'basketball', 'name': 'Basketball', 'subtitle': 'Full / half court', 'icon': Icons.sports_basketball},
];

class Step1Sports extends StatefulWidget {
  final bool isEdit;
  const Step1Sports({super.key, required this.isEdit});

  @override
  State<Step1Sports> createState() => _Step1SportsState();
}

class _Step1SportsState extends State<Step1Sports> {
  Map<String, int> _sportsConfig = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final data = context.read<GroundFormCubit>().data;
    _sportsConfig = Map.from(data.sportsConfig);
    for (final cat in data.categories) {
      _sportsConfig.putIfAbsent(cat, () => 1);
    }
    _initialized = true;
  }

  void _toggle(String id) {
    setState(() {
      final updated = Map<String, int>.from(_sportsConfig);
      if (updated.containsKey(id)) {
        updated.remove(id);
      } else {
        updated[id] = 1;
      }
      _sportsConfig = updated;
    });
  }

  void _updateCount(String id, int delta) {
    setState(() {
      final next = (_sportsConfig[id] ?? 1) + delta;
      if (next >= 1) {
        _sportsConfig = Map<String, int>.from(_sportsConfig)..[id] = next;
      }
    });
  }

  void _onNext() {
    if (_sportsConfig.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Select at least one sport'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(
      categories: _sportsConfig.keys.toList(),
      sportsConfig: Map.from(_sportsConfig),
    ));
    cubit.goToStep(2);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 1,
      title: 'Sports & Courts',
      subtitle: 'Which sports are offered at this ground?',
      onNext: _onNext,
      onBack: () => Navigator.pop(context),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _kSports.length,
        itemBuilder: (context, index) {
          final sport = _kSports[index];
          final id = sport['id'] as String;
          final isSelected = _sportsConfig.containsKey(id);
          final count = _sportsConfig[id] ?? 1;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : AppColors.primaryDarkGreen.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFF0F9F4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDarkGreen.withOpacity(0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(sport['icon'] as IconData,
                          color: AppColors.primaryDarkGreen, size: 22),
                    ),
                    const AppSizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                              text: sport['name'] as String,
                              size: 15,
                              weight: FontWeight.w700),
                          AppText(
                              text: sport['subtitle'] as String,
                              size: 12,
                              color: AppColors.textSecondaryLight),
                        ],
                      ),
                    ),
                    Switch(
                      value: isSelected,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primaryDarkGreen,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                      onChanged: (_) => _toggle(id),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE0ECE5)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: 'Number of courts / pitches',
                        size: 13,
                        color: AppColors.textSecondaryLight,
                        weight: FontWeight.w500,
                      ),
                      _Counter(
                        count: count,
                        onDecrement: () => _updateCount(id, -1),
                        onIncrement: () => _updateCount(id, 1),
                      ),
                    ],
                  ),
                  if (count > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppText(
                        text: '$count ${sport['name']} courts at this ground',
                        size: 12,
                        color: AppColors.primaryDarkGreen,
                        weight: FontWeight.w600,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _Counter({required this.count, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Btn(icon: Icons.remove, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: AppText(
            text: count.toString(),
            size: 17,
            weight: FontWeight.w800,
            color: AppColors.primaryDarkGreen,
          ),
        ),
        _Btn(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 14, color: AppColors.primaryDarkGreen),
      ),
    );
  }
}
