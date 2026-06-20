import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

class DashboardHeader extends StatelessWidget {
  final String ownerName;
  final String venueName;
  final int activeCourts;

  const DashboardHeader({
    super.key,
    required this.ownerName,
    required this.venueName,
    required this.activeCourts,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "O";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 48, // Padding so RevenueCard can overlap
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkGreen,
        // No bottom radius, straight edge to match Figma
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "Good morning, $ownerName 👋",
                      color: Colors.white.withOpacity(0.9),
                      size: 14,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      text: venueName,
                      color: Colors.white,
                      size: 24,
                      weight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification03,
                      color: AppColors.goldenYellow,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppText(
                        text: _getInitials(ownerName),
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDarkGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const AppText(
                      text: "Live on CricBook",
                      color: AppColors.primaryDarkGreen,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  text: "$activeCourts Courts Active",
                  color: Colors.white,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
