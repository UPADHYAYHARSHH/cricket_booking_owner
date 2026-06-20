import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/quick_action_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/revenue_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/slot_item.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/stat_card.dart';
import 'package:hugeicons/hugeicons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const _DashboardSkeleton();
            }

            if (state is DashboardError) {
              return Center(
                child: AppText(
                  text: state.message,
                  color: AppColors.error,
                ),
              );
            }

            if (state is DashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header and Overlapping Revenue Card
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            DashboardHeader(
                              ownerName: state.ownerName,
                              venueName: state.venueName,
                              activeCourts: state.activeCourts,
                            ),
                            const SizedBox(height: 50), // Space for revenue card overlap
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: RevenueCard(
                            amount: state.todayRevenue,
                            percentageChange: "24%", // Still mocked for now until we have historical data
                            bookingsCount: state.todayBookingsCount.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          StatCard(value: state.todayBookingsCount.toString(), label: "Today's Bookings"),
                          const SizedBox(width: 12),
                          StatCard(value: state.pendingAcceptCount.toString(), label: "Pending Accept"),
                          const SizedBox(width: 12),
                          StatCard(value: state.occupancyPercentage, label: "Occupancy"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Today's Slots Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: "TODAY'S SLOTS",
                            color: AppColors.primaryDarkGreen,
                            size: 14,
                            weight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          AppText(
                            text: "Tue, 6 May",
                            color: AppColors.primaryDarkGreen.withOpacity(0.8),
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slots Grid/List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: state.todaySlots.isNotEmpty
                          ? Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: state.todaySlots.map((slot) {
                                return SlotItem(
                                  time: slot['period'] ?? 'Time',
                                  subtitle: 'Booked', // Can map to user later
                                  type: SlotType.booked,
                                );
                              }).toList(),
                            )
                          : const AppText(
                              text: "No bookings for today yet.",
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Pending Approvals Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: "PENDING APPROVALS",
                            color: AppColors.primaryDarkGreen,
                            size: 14,
                            weight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          if (state.pendingAcceptCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppText(
                                text: "${state.pendingAcceptCount} new",
                                color: const Color(0xFFE53935),
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pending Approvals List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: state.pendingApprovals.isNotEmpty
                          ? Column(
                              children: state.pendingApprovals.map((approval) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PendingApprovalCard(
                                    name: "Customer Booking",
                                    details: "${approval['ground_name']} • ${approval['period'] ?? 'Time'}",
                                    advanceInfo: "₹${approval['amount'] ?? 0} total",
                                    onAccept: () {
                                      // TODO: Implement accept
                                    },
                                    onDecline: () {
                                      // TODO: Implement decline
                                    },
                                  ),
                                );
                              }).toList(),
                            )
                          : const AppText(
                              text: "No pending approvals right now.",
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: AppText(
                        text: "QUICK ACTIONS",
                        color: AppColors.primaryDarkGreen,
                        size: 14,
                        weight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.6, // Width / Height
                        children: [
                          QuickActionCard(
                            title: "Manage Slots",
                            icon: Image.asset('assets/icons/calendar.png', height: 32, errorBuilder: (context, error, stackTrace) => const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 32.0, color: AppColors.accentOrange)),
                            onTap: () {},
                          ),
                          QuickActionCard(
                            title: "All Bookings",
                            icon: Image.asset('assets/icons/clipboard.png', height: 32, errorBuilder: (context, error, stackTrace) => const HugeIcon(icon: HugeIcons.strokeRoundedTaskDone01, size: 32.0, color: Colors.blueGrey)),
                            onTap: () {},
                          ),
                          QuickActionCard(
                            title: "Revenue Report",
                            icon: Image.asset('assets/icons/money_bag.png', height: 32, errorBuilder: (context, error, stackTrace) => const HugeIcon(icon: HugeIcons.strokeRoundedMoneyBag01, size: 32.0, color: Colors.green)),
                            onTap: () {},
                          ),
                          QuickActionCard(
                            title: "Settings",
                            icon: Image.asset('assets/icons/settings.png', height: 32, errorBuilder: (context, error, stackTrace) => const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, size: 32.0, color: Colors.grey)),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 16, width: 120, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (index) => Container(width: 100, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

