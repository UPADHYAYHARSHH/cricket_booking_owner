import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/blocs/bookings/bookings_state.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BookingsCubit>().fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppText(text: "Bookings", size: 18, weight: FontWeight.w700),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<BookingsCubit>().searchBookings(query);
              },
              decoration: InputDecoration(
                hintText: "Search by player name or booking ID",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryDarkGreen),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                if (state is BookingsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BookingsError) {
                  return Center(
                    child: AppText(text: state.message, color: AppColors.error),
                  );
                } else if (state is BookingsLoaded) {
                  if (state.filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedSearch02, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const AppText(text: "No bookings found", size: 16, color: Colors.grey),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<BookingsCubit>().fetchBookings();
                    },
                    color: AppColors.primaryDarkGreen,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.filteredBookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = state.filteredBookings[index];
                        return _BookingCard(booking: booking);
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF57C00); // Amber text
      case 'confirmed':
      case 'completed':
        return const Color(0xFF2E6A4F); // Green text
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red text
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF8E1); // Light amber
      case 'confirmed':
      case 'completed':
        return const Color(0xFFE8F5E9); // Light green
      case 'cancelled':
        return const Color(0xFFFFEBEE); // Light red
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getCardBorderColor(String status) {
    if (status.toLowerCase() == 'pending') {
      return const Color(0xFFFFCA28); // Amber border for pending
    }
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    
    final playerName = booking['player_name'] ?? 'Player Name';
    final groundName = booking['ground_name'] ?? 'Court';
    final period = booking['period'] ?? 'Time';
    final sportName = booking['sport_name'] ?? 'Sport';
    final amount = booking['amount'] ?? booking['total_amount'] ?? 0;
    
    // Formatting booking ID
    String displayId = booking['display_id']?.toString() ?? '';
    if (displayId.isEmpty) {
      final fullId = booking['id']?.toString() ?? '';
      displayId = fullId.length > 5 ? fullId.substring(0, 5).toUpperCase() : fullId;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCardBorderColor(status), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: playerName,
                size: 16,
                weight: FontWeight.w700,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  text: status[0].toUpperCase() + status.substring(1),
                  color: statusColor,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            text: "$groundName • $period",
            size: 13,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: HugeIcons.strokeRoundedCricketBat, text: sportName),
              const SizedBox(width: 12),
              _InfoChip(icon: HugeIcons.strokeRoundedUserGroup, text: "Players"), // Mocked players
              const SizedBox(width: 12),
              _InfoChip(icon: HugeIcons.strokeRoundedMoneyBag01, text: "₹$amount"),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            text: "Booking #CB$displayId",
            size: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          // Actions Row - Only Details Button as per requirements
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // Navigate to details
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDarkGreen,
                  side: const BorderSide(color: AppColors.primaryDarkGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const AppText(
                  text: "Details",
                  color: AppColors.primaryDarkGreen,
                  weight: FontWeight.w600,
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        AppText(text: text, size: 12, color: Colors.grey.shade700),
      ],
    );
  }
}
