import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:ui';

class DashboardHeader extends StatefulWidget {
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

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
        bottom: 56,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkGreen,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                        text: "${_getGreeting()}, ${widget.ownerName}",
                        color: AppColors.white,
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildGlassCircle(
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification03,
                        color: AppColors.white,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildGlassCircle(
                      AppText(
                        text: _getInitials(widget.ownerName),
                        color: AppColors.white,
                        weight: FontWeight.w700,
                      ),
                      bordered: true,
                    ),
                  ],
                ),
              ],
            ),
            if (widget.locations.length > 1) ...[
              const SizedBox(height: 20),
              LocationDropdown(
                locations: widget.locations,
                selectedLocationId: widget.selectedLocationId,
                onSelected: widget.onLocationSelected,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppText(
                        text: "${widget.activeCourts} Courts Active",
                        color: AppColors.white,
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
      ),
    );
  }

  Widget _buildGlassCircle(Widget child, {VoidCallback? onTap, bool bordered = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: bordered
                  ? Border.all(
                      color: AppColors.white.withValues(alpha: 0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
