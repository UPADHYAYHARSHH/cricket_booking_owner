import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: now, end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryDarkGreen,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    context.read<BookingsCubit>().setDateRange(picked.start, picked.end);
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<BookingsCubit>().searchBookings(query);
              },
              decoration: InputDecoration(
                hintText: "Search by player name, ground or booking ID",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.grey.shade400),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                      onPressed: () {
                        _searchController.clear();
                        context.read<BookingsCubit>().searchBookings('');
                      },
                    );
                  },
                ),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                final dateFilter =
                    state is BookingsLoaded ? state.dateFilter : BookingDateFilter.all;
                final rangeStart = state is BookingsLoaded ? state.rangeStart : null;
                final rangeEnd = state is BookingsLoaded ? state.rangeEnd : null;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DateFilterChip(
                        label: 'All',
                        selected: dateFilter == BookingDateFilter.all,
                        onTap: () => context.read<BookingsCubit>().setDateFilter(BookingDateFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: 'Today',
                        selected: dateFilter == BookingDateFilter.today,
                        onTap: () => context.read<BookingsCubit>().setDateFilter(BookingDateFilter.today),
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: 'Tomorrow',
                        selected: dateFilter == BookingDateFilter.tomorrow,
                        onTap: () =>
                            context.read<BookingsCubit>().setDateFilter(BookingDateFilter.tomorrow),
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: dateFilter == BookingDateFilter.range && rangeStart != null && rangeEnd != null
                            ? '${DateFormat('d MMM').format(rangeStart)} – ${DateFormat('d MMM').format(rangeEnd)}'
                            : 'Date Range',
                        icon: Icons.date_range_rounded,
                        selected: dateFilter == BookingDateFilter.range,
                        onTap: _pickDateRange,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                if (state is BookingsLoading) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => const _BookingSkeleton(),
                  );
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

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _pressed = false;

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: widget.booking),
      ),
    );
  }

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
    final booking = widget.booking;
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _openDetails,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primaryDarkGreen.withOpacity(0.08),
            highlightColor: AppColors.primaryDarkGreen.withOpacity(0.04),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
                      _InfoChip(
                        icon: sportIcon(sportName.toString()),
                        text: formatSportName(sportName.toString()),
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(icon: HugeIcons.strokeRoundedUserGroup, text: "Players"), // Mocked players
                      const SizedBox(width: 12),
                      _InfoChip(icon: HugeIcons.strokeRoundedMoneyBag01, text: "₹$amount"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: "Booking #CB$displayId",
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            text: "View Details",
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.primaryDarkGreen,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _DateFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkGreen : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDarkGreen : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 5),
            ],
            AppText(
              text: label,
              size: 13,
              weight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ],
        ),
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

class _BookingSkeleton extends StatelessWidget {
  const _BookingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 80,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

