import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingsCubit>().fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        title: const AppText(
          text: 'Payouts',
          size: 18,
          weight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDarkGreen,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primaryDarkGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Settled"),
          ],
        ),
      ),
      body: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) {
          if (state is BookingsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryDarkGreen));
          } else if (state is BookingsError) {
            return Center(child: AppText(text: state.message, color: AppColors.error));
          } else if (state is BookingsLoaded) {
            // Filter all bookings manually for payout status
            final allBookings = state.allBookings;
            final pending = allBookings.where((b) {
              final status = b['payout_status']?.toString().toLowerCase();
              return status == 'pending' || status == null;
            }).toList();
            
            final settled = allBookings.where((b) {
              final status = b['payout_status']?.toString().toLowerCase();
              return status == 'settled';
            }).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _PayoutList(bookings: pending, isPending: true),
                _PayoutList(bookings: settled, isPending: false),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PayoutList extends StatelessWidget {
  final List<dynamic> bookings;
  final bool isPending;

  const _PayoutList({required this.bookings, required this.isPending});

  double _getOwnerEarnings(Map<String, dynamic> booking) {
    if (booking['owner_earnings'] != null) {
      return (booking['owner_earnings'] as num).toDouble();
    }
    return ((booking['amount'] ?? booking['total_amount'] ?? 0) as num).toDouble();
  }

  String _formatSportSlug(String slug) {
    if (slug.isEmpty) return 'Sport';
    return slug
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
            const SizedBox(height: AppSizes.md),
            AppText(
              text: isPending ? "No pending payouts!" : "No settled payouts yet.",
              color: AppColors.textSecondaryLight,
              weight: FontWeight.w600,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.lg),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final booking = bookings[index] as Map<String, dynamic>;
        final earning = _getOwnerEarnings(booking);
        
        final dateStr = booking['slot_time'] ?? booking['created_at'];
        String formattedDate = '';
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr.toString())?.toLocal();
          if (dt != null) {
            formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
          }
        }
        
        final groundName = (booking['grounds'] as Map?)?['name']?.toString() ?? booking['ground_name']?.toString() ?? 'Ground';
        final rawSport = booking['sport_name']?.toString() ?? booking['sport']?.toString() ?? '';
        final sportName = _formatSportSlug(rawSport);
        
        final rawDisplayId = booking['display_id'];
        final displayId = (rawDisplayId != null && rawDisplayId.toString() != '0')
            ? rawDisplayId.toString()
            : booking['id'].toString().substring(0, 8);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailsScreen(booking: booking),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Booking ID and Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLg - 1),
                      topRight: Radius.circular(AppSizes.radiusLg - 1),
                    ),
                    border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          AppText(
                            text: "CB$displayId",
                            size: 13,
                            weight: FontWeight.bold,
                            color: AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPending ? Colors.orange : AppColors.primaryDarkGreen).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: (isPending ? Colors.orange : AppColors.primaryDarkGreen).withValues(alpha: 0.3)),
                        ),
                        child: AppText(
                          text: isPending ? "Pending" : "Settled",
                          size: 11,
                          weight: FontWeight.w700,
                          color: isPending ? Colors.orange.shade800 : AppColors.primaryDarkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Body: Ground, Sport, Date, and Amount
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sports_tennis_rounded, size: 16, color: AppColors.primaryDarkGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: AppText(
                                    text: groundName, 
                                    weight: FontWeight.bold, 
                                    size: 15,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.directions_run_rounded, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 6),
                                AppText(text: sportName, size: 13, color: AppColors.textSecondaryLight),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 8),
                                AppText(text: formattedDate, size: 12, color: AppColors.textSecondaryLight),
                              ],
                            ),
                            if (booking['payout_reference'] != null && booking['payout_reference'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, size: 12, color: AppColors.primaryDarkGreen),
                                    const SizedBox(width: 4),
                                    AppText(
                                      text: "Ref: ${booking['payout_reference']}",
                                      size: 11,
                                      color: AppColors.primaryDarkGreen,
                                      weight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Right side amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            const AppText(
                              text: "You Earn",
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              text: "₹${earning.toInt()}",
                              weight: FontWeight.w800,
                              size: 18,
                              color: AppColors.textPrimaryLight,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
