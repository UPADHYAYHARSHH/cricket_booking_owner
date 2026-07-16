import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/domain/models/virtual_slot.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_state.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final ScrollController _dateScrollController = ScrollController();
  DateTime? _lastScrolledDate;
  String _selectedTimeFilter = 'All';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<SlotCubit, SlotState>(
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
                  _buildHeader(state.venueName),
                  Expanded(
                    child: state.grounds.isEmpty
                        ? _buildNoGroundsView(context, state)
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildGroundSelector(state),
                                const SizedBox(height: 24),
                                _buildDateSelector(state),
                                const SizedBox(height: 24),
                                _buildSlotHeader(context, state),
                                const SizedBox(height: 16),
                                _buildLegend(),
                                const SizedBox(height: 16),
                                _buildTimeFilters(),
                                const SizedBox(height: 16),
                                _buildSlotGrid(context, state),
                                const SizedBox(height: 24),
                                _buildSummaryCard(state),
                                const SizedBox(height: 24),
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
              color: Colors.grey.shade300,
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
              color: Colors.grey.shade600,
              align: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const AppText(
                text: "Create Ground",
                size: 14,
                weight: FontWeight.w600,
                color: Colors.white,
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

  Widget _buildHeader(String venueName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.primaryDarkGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "Slot Management",
            size: 24,
            weight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          AppText(text: venueName, size: 14, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildGroundSelector(SlotLoaded state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: state.grounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: isSelected
                        ? Colors.orange.shade300
                        : Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    text: "Court ${index + 1} — ${ground['name']}",
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    size: 14,
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
    final lastDay = DateTime(today.year, today.month + 1, 0);
    final daysInMonth = lastDay.day;
    final dates = List.generate(
      daysInMonth,
      (i) => DateTime(today.year, today.month, i + 1),
    );

    int selectedIndex = dates.indexWhere((d) => _isSameDay(d, state.selectedDate));
    if (selectedIndex == -1) selectedIndex = 0;

    if (_lastScrolledDate == null || !_isSameDay(_lastScrolledDate!, state.selectedDate)) {
      _lastScrolledDate = state.selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dateScrollController.hasClients) {
          final screenWidth = MediaQuery.of(context).size.width;
          const itemWidth = 52.0;
          const separatorWidth = 16.0;
          const totalItemWidth = itemWidth + separatorWidth;
          
          final offset = (selectedIndex * totalItemWidth) - (screenWidth / 2) + (itemWidth / 2) + 16.0;
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
      height: 70,
      child: ListView.separated(
        controller: _dateScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, state.selectedDate);

          return GestureDetector(
            onTap: () => context.read<SlotCubit>().selectDate(date),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: DateFormat('EEE').format(date).toUpperCase(),
                    size: 12,
                    color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    weight: FontWeight.w500,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "${date.day}",
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.shade300
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
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
    final courtName = groundIndex != -1 ? "COURT ${groundIndex + 1}" : "";
    final dateStr = DateFormat(
      'EEE, MMM d',
    ).format(state.selectedDate).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            text: "$dateStr — $courtName",
            size: 14,
            color: AppColors.primaryDarkGreen,
            weight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _LegendChip(
            label: "Open",
            color: Colors.green.shade100,
            textColor: Colors.green.shade800,
            iconColor: Colors.green.shade700,
          ),
          _LegendChip(
            label: "Booked",
            color: Colors.grey.shade100,
            textColor: Colors.grey.shade600,
            iconColor: Colors.grey.shade500,
          ),
          _LegendChip(
            label: "Owner Booked",
            color: Colors.blue.shade50,
            textColor: Colors.blue.shade700,
            iconColor: Colors.blue.shade400,
          ),
          _LegendChip(
            label: "Peak",
            color: Colors.orange.shade50,
            textColor: Colors.orange.shade800,
            iconColor: Colors.orange.shade600,
            isPeak: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['All', 'Morning', 'Afternoon', 'Evening', 'Night'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedTimeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                ),
              ),
              child: AppText(
                text: filter,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                size: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid(BuildContext context, SlotLoaded state) {
    List<VirtualSlot> filteredSlots = state.slots;
    
    if (_selectedTimeFilter != 'All') {
      filteredSlots = state.slots.where((slot) {
        final hour = slot.startTime.hour;
        switch (_selectedTimeFilter) {
          case 'Morning':
            return hour >= 6 && hour < 12;
          case 'Afternoon':
            return hour >= 12 && hour < 16;
          case 'Evening':
            return hour >= 16 && hour < 20;
          case 'Night':
            return hour >= 20 || hour < 6;
          default:
            return true;
        }
      }).toList();
    }

    if (filteredSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: AppText(
            text: "No slots available for $_selectedTimeFilter.",
            color: Colors.grey,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredSlots.length,
        itemBuilder: (context, index) {
          final slot = filteredSlots[index];
          return _SlotCard(
            slot: slot,
            onTap: () => _handleSlotTap(context, slot),
          );
        },
      ),
    );
  }

  void _handleSlotTap(BuildContext context, VirtualSlot slot) {
    switch (slot.status) {
      case SlotStatus.booked:
      case SlotStatus.blocked:
      case SlotStatus.maintenance:
        if (slot.bookingDetails != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(booking: slot.bookingDetails!),
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
      barrierColor: Colors.black.withOpacity(0.45),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withOpacity(0.25),
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
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPeak
                              ? [
                                  Colors.orange.shade500,
                                  Colors.deepOrange.shade400,
                                ]
                              : [Colors.blue.shade600, Colors.indigo.shade500],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Book This Slot",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time range card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: (isPeak ? Colors.orange : Colors.blue)
                                  .shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isPeak ? Colors.orange : Colors.blue)
                                    .shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 20,
                                  color: (isPeak ? Colors.orange : Colors.blue)
                                      .shade600,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "$startStr – $endStr",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color:
                                          (isPeak ? Colors.orange : Colors.blue)
                                              .shade800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    durationLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (isPeak ? Colors.orange : Colors.blue)
                                              .shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  icon: isPeak
                                      ? Icons.bolt_rounded
                                      : Icons.event_seat_rounded,
                                  label: isPeak ? "Peak Slot" : "Regular Slot",
                                  color: isPeak
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                  bgColor: isPeak
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoChip(
                                  icon: Icons.currency_rupee_rounded,
                                  label: "₹${slot.price}",
                                  color: AppColors.primaryDarkGreen,
                                  bgColor: AppColors.primaryDarkGreen
                                      .withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "This slot will be marked as Booked by Owner and won't be available for customer bookings.",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: reasonController,
                            decoration: InputDecoration(
                              hintText: "Optional note (e.g., Maintenance)",
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: isPeak
                                    ? Colors.orange.shade600
                                    : Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

  void _showUnblockDialog(BuildContext context, VirtualSlot slot) {
    final timeFormat = DateFormat('h:mm a');
    final startStr = timeFormat.format(slot.startTime);
    final endStr = timeFormat.format(slot.endTime);
    final dateStr = DateFormat('EEE, d MMM').format(slot.startTime);
    final durationMins = slot.endTime.difference(slot.startTime).inMinutes;
    final durationLabel = durationMins % 60 == 0
        ? "${durationMins ~/ 60} hr"
        : "${(durationMins / 60).toStringAsFixed(1)} hr";

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Unblock Slot",
      barrierColor: Colors.black.withOpacity(0.45),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withOpacity(0.25),
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
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blueGrey.shade600,
                            Colors.blueGrey.shade400,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_open_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Unblock This Slot",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time range card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blueGrey.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 20,
                                  color: Colors.blueGrey.shade600,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "$startStr – $endStr",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    durationLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  icon: Icons.info_outline_rounded,
                                  label: "Owner Booked",
                                  color: Colors.blueGrey.shade700,
                                  bgColor: Colors.blueGrey.shade50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Reason: ${slot.blockReason ?? 'Booked by owner'}\n\nMake this slot available for booking again?",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: AppColors.primaryDarkGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                if (slot.blockedSlotId != null) {
                                  context.read<SlotCubit>().unbookOwnerSlot(
                                    slot.blockedSlotId!,
                                  );
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_open_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Unblock Slot",
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

  void _showBookingInfoSheet(BuildContext context, VirtualSlot slot) {
    final timeFormat = DateFormat('h:mm a');
    final timeRange =
        "${timeFormat.format(slot.startTime)} – ${timeFormat.format(slot.endTime)}";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_available,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Booked Slot",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              label: "Player",
              value: slot.bookedPlayerName ?? 'Unknown',
            ),
            const SizedBox(height: 10),
            _InfoRow(label: "Amount", value: "₹${slot.price}"),
            const SizedBox(height: 10),
            _InfoRow(
              label: "Booking ID",
              value: slot.bookingId?.substring(0, 8) ?? '—',
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "This slot is booked and cannot be blocked.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SlotLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(text: "Booked today", color: Colors.grey.shade600),
              AppText(
                text: "${state.bookedCount} / ${state.totalSlots} slots",
                color: AppColors.primaryDarkGreen,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(text: "Blocked slots", color: Colors.grey.shade600),
              AppText(
                text: "${state.blockedCount} slots",
                color: Colors.blue.shade700,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: "Today's revenue (confirmed)",
                color: Colors.grey.shade600,
              ),
              AppText(
                text: "₹${state.todayRevenue}",
                color: AppColors.primaryDarkGreen,
                weight: FontWeight.bold,
                size: 16,
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
  final Color color;
  final Color textColor;
  final Color iconColor;
  final bool isPeak;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.textColor,
    required this.iconColor,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPeak)
            HugeIcon(
              icon: HugeIcons.strokeRoundedEnergy,
              size: 12,
              color: iconColor,
            )
          else
            Container(width: 6, height: 6, color: iconColor),
          const SizedBox(width: 6),
          AppText(
            text: label,
            size: 12,
            color: textColor,
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

    Color bgColor;
    Color borderColor;
    Widget content;

    switch (slot.status) {
      case SlotStatus.open:
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: timeRange,
              size: 12,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 4),
            AppText(
              text: "Open • ₹${slot.price}",
              size: 11,
              color: Colors.green.shade700,
            ),
          ],
        );
        break;

      case SlotStatus.booked:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade200;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: timeRange,
              size: 12,
              color: Colors.grey.shade500,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 2),
            AppText(
              text: "${slot.bookedPlayerName ?? 'Booked'} • ₹${slot.price}",
              size: 11,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 2),
            AppText(
              text: "${slot.bookedPlayersCount ?? 0} players",
              size: 10,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(text: "Details ", size: 10, color: Colors.blue.shade600, weight: FontWeight.w700),
                Icon(Icons.arrow_forward_ios, size: 8, color: Colors.blue.shade600),
              ]
            ),
          ],
        );
        break;

      case SlotStatus.blocked:
      case SlotStatus.maintenance:
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppText(
              text: timeRange,
              size: 12,
              color: Colors.blue.shade700,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 2),
            AppText(
              text: "Booked by Owner",
              size: 11,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 2),
            AppText(
              text: slot.blockReason ?? "—",
              size: 9,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(text: "Details ", size: 10, color: Colors.blue.shade600, weight: FontWeight.w700),
                Icon(Icons.arrow_forward_ios, size: 8, color: Colors.blue.shade600),
              ]
            ),
          ],
        );
        break;

      case SlotStatus.peak:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: timeRange,
              size: 12,
              color: Colors.orange.shade800,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 4),
            AppText(
              text: "Peak • ₹${slot.price}",
              size: 11,
              color: Colors.orange.shade800,
            ),
          ],
        );
        break;
    }

    final isInteractive = true;

    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: slot.status == SlotStatus.peak ? 1.5 : 1,
          ),
        ),
        child: content,
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
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
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
          height: 100,
          color: AppColors.primaryDarkGreen,
          width: double.infinity,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 120,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                        (_) => Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: 8,
                      itemBuilder: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
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
