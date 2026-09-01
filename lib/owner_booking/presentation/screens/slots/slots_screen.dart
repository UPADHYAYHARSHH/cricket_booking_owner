import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';

import '../../blocs/location/location_state.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final ScrollController _dateScrollController = ScrollController();
  DateTime? _lastScrolledDate;

  @override
  void initState() {
    super.initState();
    context.read<SlotCubit>().fetchInitialData();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: BlocBuilder<SlotCubit, SlotState>(
          builder: (context, state) {
            if (state is SlotLoading || state is SlotInitial) {
              return const _SlotsSkeleton();
            } else if (state is SlotError) {
              return Center(
                child: AppText(text: state.message, color: AppColors.error),
              );
            } else if (state is SlotLoaded) {
              return Column(
                children: [
                  _buildHeader(context, state.venueName),
                  Expanded(
                    child: state.grounds.isEmpty
                        ? _buildNoGroundsView(context, state)
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSizes.lg),
                                _buildGroundSelector(state),
                                const SizedBox(height: AppSizes.xxl),
                                _buildDateSelector(state),
                                const SizedBox(height: AppSizes.xxl),
                                _buildSlotHeader(context, state),
                                const SizedBox(height: AppSizes.lg),
                                _buildLegend(),
                                const SizedBox(height: AppSizes.lg),
                                _buildGroupedSlotGrid(context, state),
                                const SizedBox(height: AppSizes.xxl),
                                _buildSummaryCard(state),
                                const SizedBox(height: AppSizes.xxl),
                                const SizedBox(height: 100), // Extra spacing for floating bottom nav
                              ],
                            ),
                          ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
    );
  }

  Widget _buildNoGroundsView(BuildContext context, SlotLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCricketBat,
              size: 64,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 16),
            const AppText(
              text: "No Grounds Available",
              size: 20,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            AppText(
              text: "There are no grounds available for the selected location.",
              size: 14,
              color: AppColors.textSecondaryLight,
              align: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const AppText(
                text: "Create Ground",
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
              onPressed: () => _navigateToCreateGround(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateGround(BuildContext context) {
    final locationId = SharedPrefsService.instance.selectedLocationId;
    if (locationId == null || locationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location from Home first.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroundFormFlow(locationId: locationId)),
    ).then((_) {
      if (context.mounted) {
        context.read<SlotCubit>().fetchInitialData();
      }
    });
  }

  Widget _buildHeader(BuildContext context, String venueName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.md,
        left: AppSizes.lg,
        right: AppSizes.lg,
        bottom: AppSizes.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDarkGreen, Color(0xFF066B3E)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.view_timeline_rounded,
              color: AppColors.white,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: "Slot Management",
                  size: 20,
                  weight: FontWeight.bold,
                  color: AppColors.white,
                ),
                const SizedBox(height: AppSizes.xxs),
                BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, locState) {
                    String locName = "All Locations";
                    if (locState is LocationLoaded) {
                      final selectedId = SharedPrefsService.instance.selectedLocationId;
                      if (selectedId != null) {
                        try {
                          final loc = locState.locations.firstWhere((l) => l['id'] == selectedId);
                          if (loc['name'] != null && loc['name'].toString().isNotEmpty) {
                            locName = loc['name'];
                          }
                        } catch (_) {}
                      }
                    }
                    return Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.white.withValues(alpha: 0.75)),
                        const SizedBox(width: 4),
                        AppText(
                          text: locName,
                          size: 13,
                          color: AppColors.white.withValues(alpha: 0.75),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundSelector(SlotLoaded state) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        scrollDirection: Axis.horizontal,
        itemCount: state.grounds.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) {
          final ground = state.grounds[index];
          final isSelected = ground['id'] == state.selectedGroundId;
          final category = (ground['category'] as String? ?? '').toLowerCase();
          final isFootball = category == 'football';
          final icon = isFootball
              ? HugeIcons.strokeRoundedFootball
              : HugeIcons.strokeRoundedCricketBat;

          return GestureDetector(
            onTap: () => context.read<SlotCubit>().selectGround(ground['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryDarkGreen.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.accentOrange,
                    size: 18,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  AppText(
                    text: "${ground['name']}",
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textPrimaryLight,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    size: 13,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(SlotLoaded state) {
    final today = DateTime.now();

    final groundIndex = state.grounds.indexWhere(
      (g) => g['id'] == state.selectedGroundId,
    );
    final selectedGround = groundIndex != -1 ? state.grounds[groundIndex] : <String, dynamic>{};
    
    dynamic rawOperatingDays = selectedGround['operating_days'];
    List<String> operatingDays = [];
    if (rawOperatingDays is List) {
      operatingDays = rawOperatingDays.map((e) => e.toString().toLowerCase()).toList();
    } else if (rawOperatingDays is String) {
      final cleaned = rawOperatingDays.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      if (cleaned.isNotEmpty) {
        operatingDays = cleaned.split(',').map((e) => e.trim().toLowerCase()).toList();
      }
    }

    debugPrint("GROUND ID: ${state.selectedGroundId}");
    debugPrint("RAW OPERATING DAYS: $rawOperatingDays");
    debugPrint("PARSED OPERATING DAYS: $operatingDays");

    final dates = List.generate(
      30,
      (i) => DateTime(today.year, today.month, today.day + i),
    ).where((date) {
      final dayStr = DateFormat('EEE').format(date).toLowerCase();
      return operatingDays.isEmpty || operatingDays.contains(dayStr);
    }).toList();

    int selectedIndex = dates.indexWhere(
      (d) => _isSameDay(d, state.selectedDate),
    );
    if (selectedIndex == -1) selectedIndex = 0;

    if (_lastScrolledDate == null ||
        !_isSameDay(_lastScrolledDate!, state.selectedDate)) {
      _lastScrolledDate = state.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dateScrollController.hasClients) {
          final screenWidth = MediaQuery.of(context).size.width;
          const itemWidth = 56.0;
          const separatorWidth = 12.0;
          const totalItemWidth = itemWidth + separatorWidth;

          final offset =
              (selectedIndex * totalItemWidth) -
              (screenWidth / 2) +
              (itemWidth / 2) +
              16.0;
          final target = offset.clamp(
            _dateScrollController.position.minScrollExtent,
            _dateScrollController.position.maxScrollExtent,
          );

          _dateScrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        controller: _dateScrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, state.selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final dayStr = DateFormat('EEE').format(date).toLowerCase();
          final isOperatingDay = operatingDays.isEmpty || operatingDays.contains(dayStr);

          return GestureDetector(
            onTap: isOperatingDay ? () => context.read<SlotCubit>().selectDate(date) : null,
            child: Opacity(
              opacity: isOperatingDay ? 1.0 : 0.4,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryDarkGreen.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: DateFormat('EEE').format(date).toUpperCase(),
                    size: 11,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondaryLight,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  AppText(
                    text: "${date.day}",
                    size: 18,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textPrimaryLight,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  if (isToday && !isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildSlotHeader(BuildContext context, SlotLoaded state) {
    final groundIndex = state.grounds.indexWhere(
      (g) => g['id'] == state.selectedGroundId,
    );
    final courtName = groundIndex != -1 ? (state.grounds[groundIndex]['name'] as String? ?? '').toUpperCase() : "";
    final dateStr = DateFormat(
      'EEE, MMM d',
    ).format(state.selectedDate).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: AppSizes.sm),
            AppText(
              text: dateStr,
              size: 13,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.w600,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.primaryDarkGreen,
                shape: BoxShape.circle,
              ),
            ),
            AppText(
              text: courtName,
              size: 13,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Wrap(
        spacing: 10,
        runSpacing: AppSizes.sm,
        children: [
          _LegendChip(
            label: "Open",
            bgColor: AppColors.slotAvailableBg,
            textColor: AppColors.success,
            dotColor: AppColors.slotAvailable,
          ),
          _LegendChip(
            label: "Booked",
            bgColor: AppColors.borderLight,
            textColor: AppColors.textSecondaryLight,
            dotColor: AppColors.slotBlocked,
          ),
          _LegendChip(
            label: "Owner Booked",
            bgColor: AppColors.statusConfirmedBg,
            textColor: AppColors.statusConfirmed,
            dotColor: AppColors.statusConfirmed,
          ),
          _LegendChip(
            label: "Passed",
            bgColor: AppColors.bgLight,
            textColor: AppColors.textSecondaryLight,
            dotColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedSlotGrid(BuildContext context, SlotLoaded state) {
    if (state.isLoadingSlots) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.md),
            for (int i = 0; i < 3; i++) ...[
              Shimmer.fromColors(
                baseColor: AppColors.borderLight,
                highlightColor: AppColors.bgLight,
                child: Container(
                  width: 140,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Shimmer.fromColors(
                baseColor: AppColors.borderLight,
                highlightColor: AppColors.bgLight,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: AppSizes.md,
                    mainAxisSpacing: AppSizes.md,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, _) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ]
          ],
        ),
      );
    }

    // Check if the current day is operating day
    final groundIndex = state.grounds.indexWhere(
      (g) => g['id'] == state.selectedGroundId,
    );
    final selectedGround = groundIndex != -1 ? state.grounds[groundIndex] : <String, dynamic>{};
    
    dynamic rawOperatingDays = selectedGround['operating_days'];
    List<String> operatingDays = [];
    if (rawOperatingDays is List) {
      operatingDays = rawOperatingDays.map((e) => e.toString().toLowerCase()).toList();
    } else if (rawOperatingDays is String) {
      final cleaned = rawOperatingDays.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      if (cleaned.isNotEmpty) {
        operatingDays = cleaned.split(',').map((e) => e.trim().toLowerCase()).toList();
      }
    }

    final dayStr = DateFormat('EEE').format(state.selectedDate).toLowerCase();
    final isOperatingDay = operatingDays.isEmpty || operatingDays.contains(dayStr);

    if (!isOperatingDay) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              AppText(
                text: "Ground is closed on this day.",
                color: AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      );
    }

    // Group slots by time period
    final Map<String, List<VirtualSlot>> grouped = {};
    for (final slot in state.slots) {
      final hour = slot.startTime.hour;
      String period;
      if (hour >= 6 && hour < 12) {
        period = 'Morning';
      } else if (hour >= 12 && hour < 16) {
        period = 'Afternoon';
      } else if (hour >= 16 && hour < 20) {
        period = 'Evening';
      } else {
        period = 'Night';
      }
      grouped.putIfAbsent(period, () => []);
      grouped[period]!.add(slot);
    }

    final periodOrder = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final periodIcons = {
      'Morning': Icons.wb_sunny_rounded,
      'Afternoon': Icons.wb_cloudy_rounded,
      'Evening': Icons.wb_twilight_rounded,
      'Night': Icons.nights_stay_rounded,
    };
    final periodColors = {
      'Morning': const Color(0xFFFFB300),
      'Afternoon': const Color(0xFFFF7043),
      'Evening': const Color(0xFFE65100),
      'Night': const Color(0xFF5C6BC0),
    };

    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: AppText(
            text: "No slots available.",
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: periodOrder.where((p) => grouped.containsKey(p)).map((period) {
          final periodSlots = grouped[period]!;
          final periodColor = periodColors[period] ?? AppColors.primaryDarkGreen;
          final periodIcon = periodIcons[period] ?? Icons.access_time;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: periodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: periodColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(periodIcon, size: 14, color: periodColor),
                    const SizedBox(width: 6),
                    AppText(
                      text: period.toUpperCase(),
                      size: 11,
                      color: periodColor,
                      weight: FontWeight.w700,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: periodColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppText(
                        text: "${periodSlots.length}",
                        size: 10,
                        color: periodColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Slots grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: AppSizes.md,
                  mainAxisSpacing: AppSizes.md,
                ),
                itemCount: periodSlots.length,
                itemBuilder: (context, index) {
                  final slot = periodSlots[index];
                  return _SlotCard(
                    slot: slot,
                    onTap: () => _handleSlotTap(context, slot),
                  );
                },
              ),
              const SizedBox(height: AppSizes.xxl),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _handleSlotTap(BuildContext context, VirtualSlot slot) {
    // Check if slot has passed
    final now = DateTime.now();
    final isExpired = slot.startTime.isBefore(now);

    if (isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This slot has already passed."),
          backgroundColor: AppColors.textSecondaryLight,
        ),
      );
      return;
    }

    switch (slot.status) {
      case SlotStatus.booked:
      case SlotStatus.blocked:
      case SlotStatus.maintenance:
        if (slot.bookingDetails != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BookingDetailsScreen(booking: slot.bookingDetails!),
            ),
          );
        }
        break;
      case SlotStatus.open:
      case SlotStatus.peak:
        _showBlockDialog(context, slot);
        break;
    }
  }

  void _showBlockDialog(BuildContext context, VirtualSlot slot) {
    final timeFormat = DateFormat('h:mm a');
    final startStr = timeFormat.format(slot.startTime);
    final endStr = timeFormat.format(slot.endTime);
    final dateStr = DateFormat('EEE, d MMM').format(slot.startTime);
    final isPeak = slot.status == SlotStatus.peak;
    final durationMins = slot.endTime.difference(slot.startTime).inMinutes;
    final durationLabel = durationMins % 60 == 0
        ? "${durationMins ~/ 60} hr"
        : "${(durationMins / 60).toStringAsFixed(1)} hr";

    final reasonController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Book Slot",
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + (curved.value.clamp(0.0, 1.2) * 0.15),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.xxl,
                        AppSizes.xl,
                        AppSizes.xl,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPeak
                              ? [
                                  AppColors.accentOrange,
                                  AppColors.statusPending,
                                ]
                              : [
                                  AppColors.statusConfirmed,
                                  AppColors.primaryDarkGreen,
                                ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusXxl),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: AppColors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            "Book This Slot",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: isPeak
                                  ? AppColors.statusPendingBg
                                  : AppColors.statusConfirmedBg,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                              border: Border.all(
                                color: isPeak
                                    ? AppColors.statusPendingBorder
                                    : AppColors.statusConfirmedBg,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 20,
                                  color: isPeak
                                      ? AppColors.statusPending
                                      : AppColors.statusConfirmed,
                                ),
                                const SizedBox(width: AppSizes.sm + 2),
                                Expanded(
                                  child: Text(
                                    "$startStr – $endStr",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isPeak
                                          ? AppColors.statusPending
                                          : AppColors.statusConfirmed,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.sm + 2,
                                    vertical: AppSizes.xs + 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    durationLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isPeak
                                          ? AppColors.statusPending
                                          : AppColors.statusConfirmed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  icon: isPeak
                                      ? Icons.bolt_rounded
                                      : Icons.event_seat_rounded,
                                  label: isPeak ? "Peak Slot" : "Regular Slot",
                                  color: isPeak
                                      ? AppColors.accentOrange
                                      : AppColors.primaryDarkGreen,
                                  bgColor: isPeak
                                      ? AppColors.statusPendingBg
                                      : AppColors.statusConfirmedBg,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm + 2),
                              Expanded(
                                child: _InfoChip(
                                  icon: Icons.currency_rupee_rounded,
                                  label: "₹${slot.price}",
                                  color: AppColors.primaryDarkGreen,
                                  bgColor: AppColors.statusConfirmedBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            "This slot will be marked as Booked by Owner and won't be available for customer bookings.",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          TextField(
                            controller: reasonController,
                            decoration: InputDecoration(
                              hintText: "Optional note (e.g., Maintenance)",
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.borderLight,
                              ),
                              filled: true,
                              fillColor: AppColors.bgLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.md,
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.sm,
                        AppSizes.xl,
                        AppSizes.xl,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.lg - 2,
                                ),
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.lg - 2,
                                ),
                                backgroundColor: isPeak
                                    ? AppColors.accentOrange
                                    : AppColors.primaryDarkGreen,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                context.read<SlotCubit>().bookOwnerSlot(
                                  slot.startTime,
                                  slot.price,
                                  note: reasonController.text.isNotEmpty
                                      ? reasonController.text
                                      : null,
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Confirm Booking",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

  }

  Widget _buildSummaryCard(SlotLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDarkGreen.withValues(alpha: 0.08),
            AppColors.primaryDarkGreen.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryStat(
                label: "Booked Today",
                value: "${state.bookedCount}/${state.totalSlots}",
                subLabel: "slots",
                icon: Icons.event_seat_rounded,
                color: AppColors.primaryDarkGreen,
              ),
              const SizedBox(width: AppSizes.lg),
              _SummaryStat(
                label: "Blocked",
                value: "${state.blockedCount}",
                subLabel: "slots",
                icon: Icons.lock_rounded,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSizes.lg),
              _SummaryStat(
                label: "Revenue",
                value: "₹${state.todayRevenue}",
                subLabel: "confirmed",
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Legend ──────────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color dotColor;
  final bool isPeak;

  const _LegendChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.dotColor,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs + 1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPeak)
            HugeIcon(
              icon: HugeIcons.strokeRoundedEnergy,
              size: 12,
              color: dotColor,
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: AppSizes.sm - 2),
          AppText(
            text: label,
            size: 11,
            color: textColor,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

// ─── Summary Stat ───────────────────────────────────────────────────────────

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSizes.iconSm, color: color),
          ),
          const SizedBox(height: AppSizes.sm - 2),
          AppText(text: value, size: 16, color: color, weight: FontWeight.bold),
          const SizedBox(height: AppSizes.xxs),
          AppText(
            text: label,
            size: 10,
            color: AppColors.textSecondaryLight,
            weight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

// ─── Slot Card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final VirtualSlot slot;
  final VoidCallback onTap;

  const _SlotCard({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final timeRange =
        "${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}";

    // Check if slot has passed
    final now = DateTime.now();
    final isExpired = slot.startTime.isBefore(now);

    switch (slot.status) {
      case SlotStatus.open:
        return isExpired ? _buildExpiredSlot(timeRange) : _buildOpenSlot(timeRange);
      case SlotStatus.booked:
        return _buildBookedSlot(timeRange);
      case SlotStatus.blocked:
      case SlotStatus.maintenance:
        return _buildBlockedSlot(timeRange);
      case SlotStatus.peak:
        return isExpired ? _buildExpiredSlot(timeRange) : _buildPeakSlot(timeRange);
    }
  }

  Widget _buildExpiredSlot(String timeRange) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusSm),
                bottomLeft: Radius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm - 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: timeRange,
                    size: 12,
                    color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 10,
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 3),
                      AppText(
                        text: "Passed",
                        size: 11,
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSlot(String timeRange) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.slotAvailable,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusSm),
                  bottomLeft: Radius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm - 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: timeRange,
                      size: 12,
                      color: AppColors.textPrimaryLight,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text: "Open • ₹${slot.price}",
                      size: 11,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedSlot(String timeRange) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.slotBlocked,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusSm),
                  bottomLeft: Radius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm - 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: timeRange,
                      size: 12,
                      color: AppColors.textSecondaryLight,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text:
                          "${slot.bookedPlayerName ?? 'Booked'} • ₹${slot.price}",
                      size: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text: "${slot.bookedPlayersCount ?? 0} players",
                      size: 10,
                      color: AppColors.borderLight,
                    ),
                    const SizedBox(height: AppSizes.xs - 1),
                    Row(
                      children: [
                        AppText(
                          text: "Details",
                          size: 10,
                          color: AppColors.statusConfirmed,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 8,
                          color: AppColors.statusConfirmed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedSlot(String timeRange) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.statusConfirmedBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: AppColors.statusConfirmed.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.statusConfirmed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusSm),
                  bottomLeft: Radius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm - 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            text: timeRange,
                            size: 12,
                            color: AppColors.statusConfirmed,
                            weight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusConfirmed,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: const AppText(
                            text: "Owner",
                            size: 8,
                            color: AppColors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text: "Booked by Owner",
                      size: 11,
                      color: AppColors.statusConfirmed,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text: slot.blockReason ?? "—",
                      size: 9,
                      color: AppColors.statusConfirmed.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: AppSizes.xs - 1),
                    Row(
                      children: [
                        AppText(
                          text: "Details",
                          size: 10,
                          color: AppColors.statusConfirmed,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 8,
                          color: AppColors.statusConfirmed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakSlot(String timeRange) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: AppColors.accentOrange.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusSm),
                  bottomLeft: Radius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm - 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 3),
                        AppText(
                          text: timeRange,
                          size: 12,
                          color: AppColors.statusPending,
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      text: "Peak • ₹${slot.price}",
                      size: 11,
                      color: AppColors.accentOrange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSizes.sm - 2),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SlotsSkeleton extends StatelessWidget {
  const _SlotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDarkGreen, Color(0xFF066B3E)],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.borderLight,
                    highlightColor: AppColors.bgLight,
                    child: Row(
                      children: List.generate(
                        2,
                        (_) => Container(
                          width: 120,
                          height: 48,
                          margin: const EdgeInsets.only(right: AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.borderLight,
                    highlightColor: AppColors.bgLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                        (_) => Container(
                          width: 56,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                // Period label shimmer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.borderLight,
                    highlightColor: AppColors.bgLight,
                    child: Container(
                      width: 140,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.borderLight,
                    highlightColor: AppColors.bgLight,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: AppSizes.md,
                            mainAxisSpacing: AppSizes.md,
                          ),
                      itemCount: 6,
                      itemBuilder: (_, _) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
