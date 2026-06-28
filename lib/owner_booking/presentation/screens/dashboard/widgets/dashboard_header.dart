import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'package:hugeicons/hugeicons.dart';

class DashboardHeader extends StatelessWidget {
  final String ownerName;
  final String venueName;
  final int activeCourts;
  final List<Map<String, dynamic>> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onLocationSelected;

  const DashboardHeader({
    super.key,
    required this.ownerName,
    required this.venueName,
    required this.activeCourts,
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationSelected,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "O";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 56, // Padding so RevenueCard can overlap
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
                      text: "${_getGreeting()}, $ownerName 👋",
                      color: Colors.white,
                      size: 20,
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
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification03,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
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
          if (locations.length > 1) ...[
            const SizedBox(height: 20),
            LocationDropdown(
              locations: locations,
              selectedLocationId: selectedLocationId,
              onSelected: onLocationSelected,
            ),
          ],
          const SizedBox(height: 20),
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
                    AppText(
                      text: "$activeCourts Courts Active",
                      color: AppColors.primaryDarkGreen,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
