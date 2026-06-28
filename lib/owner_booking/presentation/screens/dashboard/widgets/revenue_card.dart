import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

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

  bool get _isNegative => percentageChange.trim().startsWith('-');
  bool get _isNumeric => percentageChange.trim().startsWith('+') || percentageChange.trim().startsWith('-');

  @override
  Widget build(BuildContext context) {
    final trendColor = _isNegative ? const Color(0xFFFFAB91) : const Color(0xFF8BE3B3);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E6A4F), Color(0xFF1F4E3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F4E3A).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: "Today's Revenue",
                  color: Colors.white.withOpacity(0.75),
                  size: 13,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 10),
                AppText(
                  text: amount,
                  color: Colors.white,
                  size: 32,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isNumeric) ...[
                            Icon(
                              _isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: trendColor,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                          ],
                          AppText(
                            text: percentageChange,
                            color: trendColor,
                            size: 11,
                            weight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        text: "vs yesterday · $bookingsCount bookings",
                        color: Colors.white.withOpacity(0.7),
                        size: 11,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoneyBag01,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.6), size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
