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
  final int unreadCount;
  final VoidCallback? onNotificationTap;

  const DashboardHeader({
    super.key,
    required this.ownerName,
    required this.venueName,
    required this.activeCourts,
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationSelected,
    this.unreadCount = 0,
    this.onNotificationTap,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  String _getSelectedLocationName() {
    if (widget.selectedLocationId == null) return "All Locations";
    try {
      final loc = widget.locations.firstWhere((l) => l['id'] == widget.selectedLocationId);
      final name = loc['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return "All Locations";
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppColors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          AppText(
                            text: _getSelectedLocationName(),
                            color: AppColors.white.withValues(alpha: 0.8),
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onNotificationTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildGlassCircle(
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedNotification03,
                              color: AppColors.white,
                              size: 20.0,
                            ),
                          ),
                          if (widget.unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
