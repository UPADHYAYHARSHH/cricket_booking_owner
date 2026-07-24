import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class RevenueCard extends StatefulWidget {
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
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  late final Animation<double> _shineAnimation;

  bool get _isNegative => widget.percentageChange.trim().startsWith('-');
  bool get _isNumeric =>
      widget.percentageChange.trim().startsWith('+') ||
      widget.percentageChange.trim().startsWith('-');

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );
    // Start shine animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _shineController.forward();
    });
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendColor = _isNegative
        ? const Color(0xFFFFAB91)
        : const Color(0xFF8BE3B3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF348F5E), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF348F5E).withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shine overlay
            AnimatedBuilder(
              animation: _shineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _shineAnimation.value * 300,
                  top: 0,
                  child: Transform.rotate(
                    angle: 15 * math.pi / 180,
                    child: Container(
                      width: 60,
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.white.withValues(alpha: 0.0),
                            AppColors.white.withValues(alpha: 0.12),
                            AppColors.white.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: "Today's Earnings",
                        color: AppColors.white.withValues(alpha: 0.75),
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                      const SizedBox(height: 10),
                      AppText(
                        text: widget.amount,
                        color: AppColors.white,
                        size: 32,
                        weight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isNumeric) ...[
                                  Icon(
                                    _isNegative
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: trendColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                AppText(
                                  text: widget.percentageChange,
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
                              text: "vs yesterday · ${widget.bookingsCount} bookings",
                              color: AppColors.white.withValues(alpha: 0.7),
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
                        color: AppColors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          color: AppColors.white,
                          size: 22.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
