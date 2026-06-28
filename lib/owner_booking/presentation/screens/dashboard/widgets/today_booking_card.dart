import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

/// A fuller booking-detail card used by the dashboard's "Today's Slots" list.
/// Mirrors the styling of `_BookingCard` on the Bookings screen so both
/// screens look consistent.
class TodayBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const TodayBookingCard({super.key, required this.booking});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'confirmed':
      case 'completed':
      case 'paid':
        return const Color(0xFF2E6A4F);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'confirmed':
      case 'completed':
      case 'paid':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _borderColor(String status) {
    if (status.toLowerCase() == 'pending') return const Color(0xFFFFCA28);
    return Colors.grey.shade200;
  }

  String _formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'pending').toString();
    final playerName = booking['player_name'] ?? 'Customer';
    final groundName = booking['ground_name'] ?? 'Court';
    final period = booking['period'] ?? 'Time';
    final sportName = _formatLabel((booking['sport_name'] ?? 'Sport').toString());
    final amount = booking['amount'] ?? booking['total_amount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(status), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  text: playerName,
                  size: 15,
                  weight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  text: _formatLabel(status),
                  color: _statusColor(status),
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
              _InfoChip(icon: HugeIcons.strokeRoundedMoneyBag01, text: "₹$amount"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailsScreen(booking: booking),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDarkGreen,
                  side: const BorderSide(color: AppColors.primaryDarkGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const AppText(
                  text: "Details",
                  color: AppColors.primaryDarkGreen,
                  weight: FontWeight.w600,
                  size: 13,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: Colors.grey.shade500, size: 14),
        const SizedBox(width: 4),
        AppText(text: text, size: 12, color: Colors.grey.shade700, weight: FontWeight.w500),
      ],
    );
  }
}
