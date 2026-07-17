import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

class TodayBookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;

  const TodayBookingCard({super.key, required this.booking});

  @override
  State<TodayBookingCard> createState() => _TodayBookingCardState();
}

class _TodayBookingCardState extends State<TodayBookingCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  String _formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.booking['status'] ?? 'pending').toString();
    final playerName = widget.booking['player_name'] ?? 'Customer';
    final groundName = widget.booking['ground_name'] ?? 'Court';
    final period = widget.booking['period'] ?? 'Time';
    final sportName = _formatLabel((widget.booking['sport_name'] ?? 'Sport').toString());
    final amount = widget.booking['amount'] ?? widget.booking['total_amount'] ?? 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.bookingStatusBorderColor(status),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bookingStatusBgColor(status),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: sportIcon((widget.booking['sport_name'] ?? '').toString()),
                              size: 18,
                              color: AppColors.bookingStatusColor(status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: playerName,
                                size: 15,
                                weight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                text: "$groundName · $period",
                                size: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bookingStatusBgColor(status),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: AppText(
                      text: _formatLabel(status),
                      color: AppColors.bookingStatusColor(status),
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    _InfoChip(
                      icon: HugeIcons.strokeRoundedMoneyBag01,
                      text: "₹$amount",
                    ),
                    const SizedBox(width: 16),
                    _InfoChip(
                      icon: sportIcon((widget.booking['sport_name'] ?? '').toString()),
                      text: sportName,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailsScreen(booking: widget.booking),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            text: "Details",
                            color: AppColors.primaryDarkGreen,
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primaryDarkGreen,
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
        HugeIcon(icon: icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        AppText(
          text: text,
          size: 12,
          color: AppColors.textSecondaryLight,
          weight: FontWeight.w500,
        ),
      ],
    );
  }
}
