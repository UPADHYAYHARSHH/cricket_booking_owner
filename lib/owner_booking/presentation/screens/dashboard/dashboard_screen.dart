import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/revenue_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/stat_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/today_booking_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/revenue/revenue_screen.dart';

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
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<DashboardCubit, DashboardState>(
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
                              locations: state.locations,
                              selectedLocationId: state.selectedLocationId,
                              onLocationSelected: (locationId) =>
                                  context.read<DashboardCubit>().selectLocation(locationId),
                            ),
                            const SizedBox(height: 110), // Space for revenue card overlap
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => getIt<RevenueCubit>(),
                                  child: const RevenueScreen(),
                                ),
                              ),
                            ),
                            child: RevenueCard(
                              amount: state.todayRevenue,
                              percentageChange: state.revenueChangeLabel,
                              bookingsCount: state.todayBookingsCount.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

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
                            text: "Today's Slots",
                            color: Colors.black87,
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                          AppText(
                            text: DateFormat('EEE, d MMM').format(DateTime.now()),
                            color: Colors.grey.shade500,
                            size: 13,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Today's Slots List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: state.todaySlots.isNotEmpty
                          ? Column(
                              children: state.todaySlots.map((slot) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TodayBookingCard(
                                    booking: slot as Map<String, dynamic>,
                                  ),
                                );
                              }).toList(),
                            )
                          : const AppText(
                              text: "No bookings for today yet.",
                              color: Colors.grey,
                            ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          ),
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

