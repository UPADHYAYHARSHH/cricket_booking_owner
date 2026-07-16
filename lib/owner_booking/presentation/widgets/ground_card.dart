import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

/// Shared ground card + empty/skeleton states, used by any screen that
/// lists an owner's grounds (single location or all locations).
class GroundCard extends StatelessWidget {
  final Map<String, dynamic> ground;
  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailabilityChanged;

  const GroundCard({
    super.key,
    required this.ground,
    required this.onEdit,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = ground['name'] as String? ?? 'Unknown Ground';
    final imageUrl = ground['imageUrl'] as String?;
    final isAvailable = ground['is_available'] != false;
    final category = ground['category'] as String? ?? '';
    final price = ground['price_per_hour'];
    final openingTime = ground['opening_time'] as String? ?? '';
    final closingTime = ground['closing_time'] as String? ?? '';

    return Opacity(
      opacity: isAvailable ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Gradient Overlay and Badge
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ImagePlaceholder(name: name, category: category),
                        )
                      : _ImagePlaceholder(name: name, category: category),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category Badge
                  if (category.isNotEmpty)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSportIcon(category),
                              size: 16,
                              color: AppColors.primaryDarkGreen,
                            ),
                            const SizedBox(width: 4),
                            AppText(
                              text: _formatSport(category),
                              size: 12,
                              color: AppColors.primaryDarkGreen,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Availability Indicator Dot
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.greenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            text: isAvailable ? 'Active' : 'Hidden',
                            size: 11,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: name,
                    size: 18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                  const SizedBox(height: 12),
                  // Chips for Price and Time
                  Row(
                    children: [
                      if (price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedMoneyBag01,
                                size: 14,
                                color: AppColors.primaryDarkGreen,
                              ),
                              const SizedBox(width: 6),
                              AppText(
                                text: '₹$price/hr',
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ],
                          ),
                        ),
                      if (price != null && openingTime.isNotEmpty)
                        const SizedBox(width: 10),
                      if (openingTime.isNotEmpty && closingTime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedClock01,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              AppText(
                                text: '$openingTime – $closingTime',
                                size: 13,
                                weight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleAvailability(context, isAvailable, name),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isAvailable ? Colors.red : AppColors.primaryDarkGreen,
                            side: BorderSide(
                              color: isAvailable ? Colors.red.shade200 : AppColors.primaryDarkGreen.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                          ),
                          label: AppText(
                            text: isAvailable ? 'Hide' : 'Show',
                            size: 14,
                            weight: FontWeight.w600,
                            color: isAvailable ? Colors.red : AppColors.primaryDarkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const AppText(
                            text: 'Manage',
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSport(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  void _toggleAvailability(BuildContext context, bool isCurrentlyAvailable, String groundName) {
    if (isCurrentlyAvailable) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const AppText(
            text: 'Disable Ground?',
            size: 16,
            weight: FontWeight.w700,
          ),
          content: AppText(
            text: 'Are you sure you want to hide "$groundName"? It will no longer be visible to players for booking.',
            size: 14,
            color: Colors.black54,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: AppText(
                text: 'Cancel',
                size: 14,
                color: Colors.grey.shade600,
                weight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                onAvailabilityChanged(false);
              },
              child: const AppText(
                text: 'Disable',
                size: 14,
                color: Color(0xFFE53935),
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      onAvailabilityChanged(true);
    }
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String name;
  final String category;
  const _ImagePlaceholder({required this.name, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.primaryDarkGreen.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSportIcon(category),
              size: 40,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(height: 8),
            AppText(text: name, size: 13, color: AppColors.primaryDarkGreen, weight: FontWeight.w600),
          ],
        ),
      ),
    );
  }
}

class EmptyGrounds extends StatelessWidget {
  final VoidCallback onAdd;
  final String title;
  final String message;
  final String buttonLabel;

  const EmptyGrounds({
    super.key,
    required this.onAdd,
    this.title = 'No Grounds Yet',
    this.message = 'Add a ground (one sport at a time) at this location to start accepting bookings.',
    this.buttonLabel = 'Add Ground',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCricketBat,
              size: 72,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            AppText(
              text: title,
              size: 20,
              weight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
            const SizedBox(height: 8),
            AppText(
              text: message,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: AppText(
                text: buttonLabel,
                size: 15,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroundsSkeleton extends StatelessWidget {
  const GroundsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

IconData _getSportIcon(String category) {
  switch (category.toLowerCase()) {
    case 'box_cricket':
    case 'cricket':
      return Icons.sports_cricket;
    case 'football':
    case 'futsal':
      return Icons.sports_soccer;
    case 'badminton':
    case 'tennis':
    case 'pickleball':
    case 'table_tennis':
      return Icons.sports_tennis;
    case 'volleyball':
      return Icons.sports_volleyball;
    case 'basketball':
      return Icons.sports_basketball;
    case 'swimming':
      return Icons.pool;
    case 'golf':
      return Icons.sports_golf;
    default:
      return Icons.sports;
  }
}
