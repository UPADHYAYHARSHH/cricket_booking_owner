import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

/// All amenity IDs paired with display labels, grouped by section.
const List<Map<String, dynamic>> _kAmenities = [
  // Basic
  {'id': 'parking', 'label': 'Parking', 'group': 'Basic'},
  {'id': 'washrooms', 'label': 'Washrooms', 'group': 'Basic'},
  {'id': 'changing_rooms', 'label': 'Changing Rooms', 'group': 'Basic'},
  {'id': 'drinking_water', 'label': 'Drinking Water', 'group': 'Basic'},
  {'id': 'waiting_area', 'label': 'Waiting / Seating Area', 'group': 'Basic'},
  // Food
  {'id': 'cafeteria', 'label': 'Cafeteria / Canteen', 'group': 'Food & Beverages'},
  {'id': 'vending_machine', 'label': 'Vending Machine', 'group': 'Food & Beverages'},
  {'id': 'water_dispenser', 'label': 'Water Dispenser', 'group': 'Food & Beverages'},
  // Safety
  {'id': 'cctv', 'label': 'CCTV Surveillance', 'group': 'Safety'},
  {'id': 'first_aid', 'label': 'First Aid Kit', 'group': 'Safety'},
  {'id': 'fire_safety', 'label': 'Fire Safety Equipment', 'group': 'Safety'},
  {'id': 'security_guard', 'label': 'Security Guard', 'group': 'Safety'},
  // Cricket equipment
  {'id': 'bat_rental', 'label': 'Bat Rental', 'group': 'Cricket Equipment'},
  {'id': 'ball_provided', 'label': 'Ball Provided', 'group': 'Cricket Equipment'},
  {'id': 'batting_pads', 'label': 'Batting Pads', 'group': 'Cricket Equipment'},
  {'id': 'helmet', 'label': 'Helmet Rental', 'group': 'Cricket Equipment'},
  {'id': 'stumps_permanent', 'label': 'Permanent Stumps', 'group': 'Cricket Equipment'},
  // Football equipment
  {'id': 'football_rental', 'label': 'Football Rental', 'group': 'Football Equipment'},
  {'id': 'goal_nets', 'label': 'Goal Nets', 'group': 'Football Equipment'},
  {'id': 'bibs', 'label': 'Bibs / Jerseys', 'group': 'Football Equipment'},
  // Tech & Services
  {'id': 'wifi', 'label': 'WiFi', 'group': 'Tech & Services'},
  {'id': 'live_scoring', 'label': 'Live Scoring Support', 'group': 'Tech & Services'},
  {'id': 'coaching', 'label': 'Coaching Available', 'group': 'Tech & Services'},
  {'id': 'video_recording', 'label': 'Video Recording', 'group': 'Tech & Services'},
  {'id': 'score_display', 'label': 'LED Score Display', 'group': 'Tech & Services'},
  {'id': 'floodlights', 'label': 'Floodlights (LED)', 'group': 'Tech & Services'},
];

class Step6Amenities extends StatefulWidget {
  final bool isEdit;
  const Step6Amenities({super.key, required this.isEdit});

  @override
  State<Step6Amenities> createState() => _Step6AmenitiesState();
}

class _Step6AmenitiesState extends State<Step6Amenities> {
  Set<String> _selected = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _selected = Set.from(context.read<GroundFormCubit>().data.amenities);
    _initialized = true;
  }

  void _onNext() {
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(amenities: _selected.toList()));
    cubit.goToStep(7);
  }

  List<String> _groups() {
    final seen = <String>{};
    final out = <String>[];
    for (final a in _kAmenities) {
      final g = a['group'] as String;
      if (seen.add(g)) out.add(g);
    }
    return out;
  }

  List<Map<String, dynamic>> _inGroup(String g) =>
      _kAmenities.where((a) => a['group'] == g).toList();

  bool _shouldShowGroup(String group) {
    // Always show common groups; hide sport-specific ones if that sport isn't selected.
    final cats = context.read<GroundFormCubit>().data.categories;
    if (group == 'Cricket Equipment') {
      return cats.contains('box_cricket') || cats.contains('cricket');
    }
    if (group == 'Football Equipment') {
      return cats.contains('football') || cats.contains('futsal');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final activeCount = _selected.length;

    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 6,
      title: 'Amenities',
      subtitle: 'What facilities does this ground offer?',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 16, color: Colors.blue.shade700),
                const AppSizedBox(width: 8),
                Expanded(
                  child: AppText(
                    text:
                        '$activeCount amenities selected — grounds with 8+ get 2× more bookings',
                    size: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          const AppSizedBox(height: 24),
          ...groups.where(_shouldShowGroup).map((group) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(group),
                  ..._inGroup(group).map((amenity) {
                    final id = amenity['id'] as String;
                    final label = amenity['label'] as String;
                    final isSel = _selected.contains(id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: AppText(
                          text: label,
                          size: 15,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                        value: isSel,
                        onChanged: (val) => setState(() {
                          if (val) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        activeColor: AppColors.primaryLightGreen,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    );
                  }),
                  const AppSizedBox(height: 20),
                ],
              )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppText(
          text: title.toUpperCase(),
          size: 12,
          weight: FontWeight.w800,
          color: AppColors.textSecondaryLight.withOpacity(0.75),
          letterSpacing: 0.5,
        ),
      );
}
