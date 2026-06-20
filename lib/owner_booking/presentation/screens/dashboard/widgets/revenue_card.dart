import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class RevenueCard extends StatelessWidget {
  final String amount;
  final String percentageChange;
  final String bookingsCount;

  const RevenueCard({
    super.key,
    required this.amount,
    required this.percentageChange,
    required this.bookingsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E6A4F), // A slightly different green from primary
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "This Month's Revenue",
            color: Colors.white.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(height: 8),
          AppText(
            text: amount,
            color: Colors.white,
            size: 32,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              AppText(
                text: "$percentageChange vs last month | $bookingsCount bookings",
                color: Colors.white.withOpacity(0.9),
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
