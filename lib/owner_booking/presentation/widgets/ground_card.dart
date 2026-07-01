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
      opacity: isAvailable ? 1 : 0.55,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImagePlaceholder(name: name),
                      )
                    : _ImagePlaceholder(name: name),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text: name, size: 16, weight: FontWeight.w700, color: const Color(0xFF212121)),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText(
                    text: _formatSport(category),
                    size: 12,
                    color: AppColors.primaryDarkGreen,
                    weight: FontWeight.w600,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (price != null) ...[
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          size: 13,
                          color: AppColors.primaryDarkGreen),
                      const SizedBox(width: 4),
                      AppText(
                        text: '₹$price/hr',
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ],
                    if (openingTime.isNotEmpty && closingTime.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      AppText(
                        text: '$openingTime – $closingTime',
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
                        ),
                        child: const AppText(
                          text: 'Manage',
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: isAvailable ? 'Available to players' : 'Hidden from players',
                      size: 12,
                      weight: FontWeight.w600,
                      color: isAvailable ? AppColors.primaryDarkGreen : Colors.grey,
                    ),
                    Switch(
                      value: isAvailable,
                      activeColor: AppColors.primaryDarkGreen,
                      onChanged: onAvailabilityChanged,
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
}

class _ImagePlaceholder extends StatelessWidget {
  final String name;
  const _ImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppColors.primaryDarkGreen.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCricketBat,
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
