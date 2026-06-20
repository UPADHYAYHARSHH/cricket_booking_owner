import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/slot/slot_state.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SlotCubit>().fetchInitialData();
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
              return Center(child: AppText(text: state.message, color: AppColors.error));
            } else if (state is SlotLoaded) {
              return Column(
                children: [
                  _buildHeader(state.venueName),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildGroundSelector(state),
                          const SizedBox(height: 24),
                          _buildDateSelector(state),
                          const SizedBox(height: 24),
                          _buildSlotHeader(state),
                          const SizedBox(height: 16),
                          _buildLegend(),
                          const SizedBox(height: 16),
                          _buildSlotGrid(state.slots),
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

  Widget _buildHeader(String venueName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkGreen,
      ),
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
          AppText(
            text: venueName,
            size: 14,
            color: Colors.white70,
          ),
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
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ground = state.grounds[index];
          final isSelected = ground['id'] == state.selectedGroundId;
          final categories = List<String>.from(ground['categories'] ?? []);
          final isFootball = categories.contains('Football');
          final icon = isFootball ? HugeIcons.strokeRoundedFootball : HugeIcons.strokeRoundedCricketBat;

          return GestureDetector(
            onTap: () {
              context.read<SlotCubit>().selectGround(ground['id']);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: isSelected ? Colors.orange.shade300 : Colors.grey.shade600,
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
    // Generate dates starting from today
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, state.selectedDate);

          return GestureDetector(
            onTap: () {
              context.read<SlotCubit>().selectDate(date);
            },
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.transparent,
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
                      color: isSelected ? Colors.orange.shade300 : Colors.green.shade300,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSlotHeader(SlotLoaded state) {
    final groundIndex = state.grounds.indexWhere((g) => g['id'] == state.selectedGroundId);
    final courtName = groundIndex != -1 ? "COURT ${groundIndex + 1}" : "";
    final dateStr = DateFormat('EEE, MMM d').format(state.selectedDate).toUpperCase();

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDarkGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppText(
              text: "+ Block Slot",
              color: AppColors.primaryDarkGreen,
              size: 12,
              weight: FontWeight.w600,
            ),
          )
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
          _LegendChip(label: "Open", color: Colors.green.shade100, textColor: Colors.green.shade800, iconColor: Colors.green.shade700),
          _LegendChip(label: "Booked", color: Colors.grey.shade100, textColor: Colors.grey.shade600, iconColor: Colors.grey.shade500),
          _LegendChip(label: "Blocked", color: Colors.red.shade50, textColor: Colors.red.shade400, iconColor: Colors.red.shade400),
          _LegendChip(label: "Peak", color: Colors.orange.shade50, textColor: Colors.orange.shade800, iconColor: Colors.orange.shade600, isPeak: true),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(List<VirtualSlot> slots) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: AppText(text: "No slots available for this date.", color: Colors.grey)),
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
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return _SlotCard(slot: slot);
        },
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
              AppText(text: "Today's revenue (confirmed)", color: Colors.grey.shade600),
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
            HugeIcon(icon: HugeIcons.strokeRoundedEnergy, size: 12, color: iconColor)
          else
            Container(width: 6, height: 6, color: iconColor),
          const SizedBox(width: 6),
          AppText(text: label, size: 12, color: textColor, weight: FontWeight.w500),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final VirtualSlot slot;

  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final timeRange = "${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}";

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
            AppText(text: timeRange, size: 12, color: AppColors.primaryDarkGreen, weight: FontWeight.w600),
            const SizedBox(height: 4),
            AppText(text: "Open • ₹${slot.price}", size: 11, color: Colors.green.shade700),
          ],
        );
        break;
      case SlotStatus.booked:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade200;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(text: timeRange, size: 12, color: Colors.grey.shade500, weight: FontWeight.w600),
            const SizedBox(height: 2),
            AppText(text: "${slot.bookedPlayerName ?? 'Booked'} • ₹${slot.price}", size: 11, color: Colors.grey.shade500),
            const SizedBox(height: 2),
            AppText(text: "${slot.bookedPlayersCount ?? 0} players", size: 10, color: Colors.grey.shade400),
          ],
        );
        break;
      case SlotStatus.blocked:
      case SlotStatus.maintenance:
        bgColor = Colors.red.shade50.withOpacity(0.5);
        borderColor = Colors.red.shade100;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(text: timeRange, size: 12, color: Colors.red.shade400, weight: FontWeight.w600),
            const SizedBox(height: 4),
            AppText(text: "Maintenance", size: 11, color: Colors.red.shade400),
          ],
        );
        break;
      case SlotStatus.peak:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(text: timeRange, size: 12, color: Colors.orange.shade800, weight: FontWeight.w600),
            const SizedBox(height: 4),
            AppText(text: "Peak • ₹${slot.price}", size: 11, color: Colors.orange.shade800),
          ],
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: slot.status == SlotStatus.peak ? 1.5 : 1),
      ),
      child: content,
    );
  }
}

class _SlotsSkeleton extends StatelessWidget {
  const _SlotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
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
                // Grounds
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Container(width: 120, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                        const SizedBox(width: 12),
                        Container(width: 120, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Dates
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) => Container(width: 40, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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

