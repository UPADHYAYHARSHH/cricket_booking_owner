import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

/// Amenity IDs paired with display labels and icons, grouped by section.
/// Shared by add-location and onboarding Step 3.
const List<Map<String, dynamic>> kVenueAmenities = [
  {
    'id': 'parking',
    'label': 'Parking',
    'group': 'Basic',
    'icon': HugeIcons.strokeRoundedCarParking01,
  },
  {
    'id': 'washrooms',
    'label': 'Washrooms',
    'group': 'Basic',
    'icon': HugeIcons.strokeRoundedToilet01,
  },
  {
    'id': 'changing_rooms',
    'label': 'Changing Rooms',
    'group': 'Basic',
    'icon': HugeIcons.strokeRoundedLocker01,
  },
  {
    'id': 'drinking_water',
    'label': 'Drinking Water',
    'group': 'Basic',
    'icon': HugeIcons.strokeRoundedDroplet,
  },
  {
    'id': 'waiting_area',
    'label': 'Waiting / Seating Area',
    'group': 'Basic',
    'icon': HugeIcons.strokeRoundedSofa01,
  },
  {
    'id': 'cafeteria',
    'label': 'Cafeteria / Canteen',
    'group': 'Food & Beverages',
    'icon': HugeIcons.strokeRoundedCafe,
  },
  {
    'id': 'vending_machine',
    'label': 'Vending Machine',
    'group': 'Food & Beverages',
    'icon': HugeIcons.strokeRoundedSoftDrink01,
  },
  {
    'id': 'water_dispenser',
    'label': 'Water Dispenser',
    'group': 'Food & Beverages',
    'icon': HugeIcons.strokeRoundedWaterPump,
  },
  {
    'id': 'cctv',
    'label': 'CCTV Surveillance',
    'group': 'Safety',
    'icon': HugeIcons.strokeRoundedCctvCamera,
  },
  {
    'id': 'first_aid',
    'label': 'First Aid Kit',
    'group': 'Safety',
    'icon': HugeIcons.strokeRoundedFirstAidKit,
  },
  {
    'id': 'fire_safety',
    'label': 'Fire Safety Equipment',
    'group': 'Safety',
    'icon': HugeIcons.strokeRoundedFireExtinguisher,
  },
  {
    'id': 'security_guard',
    'label': 'Security Guard',
    'group': 'Safety',
    'icon': HugeIcons.strokeRoundedUserShield01,
  },
  {
    'id': 'bat_rental',
    'label': 'Bat Rental',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedCricketBat,
  },
  {
    'id': 'ball_provided',
    'label': 'Ball Provided',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedBaseball,
  },
  {
    'id': 'batting_pads',
    'label': 'Batting Pads',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedShield01,
  },
  {
    'id': 'helmet',
    'label': 'Helmet Rental',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedCricketHelmet,
  },
  {
    'id': 'stumps_permanent',
    'label': 'Permanent Stumps',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedUtilityPole,
  },
  {
    'id': 'football_rental',
    'label': 'Football Rental',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedFootball,
  },
  {
    'id': 'goal_nets',
    'label': 'Goal Nets',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedFootballPitch,
  },
  {
    'id': 'bibs',
    'label': 'Bibs / Jerseys',
    'group': 'Equipment',
    'icon': HugeIcons.strokeRoundedTShirt,
  },
  {
    'id': 'wifi',
    'label': 'WiFi',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedWifi01,
  },
  {
    'id': 'live_scoring',
    'label': 'Live Scoring Support',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedAnalyticsUp,
  },
  {
    'id': 'coaching',
    'label': 'Coaching Available',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedWhistle,
  },
  {
    'id': 'video_recording',
    'label': 'Video Recording',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedCameraVideo,
  },
  {
    'id': 'score_display',
    'label': 'LED Score Display',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedModernTv,
  },
  {
    'id': 'floodlights',
    'label': 'Floodlights (LED)',
    'group': 'Tech & Services',
    'icon': HugeIcons.strokeRoundedSpotlight,
  },
];

class AmenitiesPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const AmenitiesPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final groups = <String>[];
    for (final a in kVenueAmenities) {
      final g = a['group'] as String;
      if (seen.add(g)) groups.add(g);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.map((group) {
        final items = kVenueAmenities
            .where((a) => a['group'] == group)
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    text: group.toUpperCase(),
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.textSecondaryLight,
                    letterSpacing: 0.8,
                  ),
                ],
              ),
              const AppSizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: items.map((amenity) {
                  final id = amenity['id'] as String;
                  final label = amenity['label'] as String;
                  final icon = amenity['icon'];
                  final isSel = selected.contains(id);
                  return GestureDetector(
                    onTap: () {
                      final next = Set<String>.from(selected);
                      if (isSel) {
                        next.remove(id);
                      } else {
                        next.add(id);
                      }
                      onChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.inputFillLight
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusRound,
                        ),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primaryDarkGreen
                              : AppColors.borderLight,
                          width: isSel ? 1.5 : 1,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryDarkGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: icon,
                            size: 16,
                            color: isSel
                                ? AppColors.primaryDarkGreen
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          AppText(
                            text: label,
                            size: 13,
                            weight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel
                                ? AppColors.primaryDarkGreen
                                : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
