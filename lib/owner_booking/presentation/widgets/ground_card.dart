import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
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
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Gradient Overlay and Badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXl),
              ),
              child: Stack(
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ImagePlaceholder(name: name, category: category),
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
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category Badge - Glass effect
                  if (category.isNotEmpty)
                    Positioned(
                      top: AppSizes.lg,
                      left: AppSizes.lg,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.lg,
                              vertical: AppSizes.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSportIcon(category),
                                  size: 14,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: AppSizes.xs),
                                AppText(
                                  text: _formatSport(category),
                                  size: 12,
                                  color: AppColors.white,
                                  weight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Availability Pill
                  Positioned(
                    top: AppSizes.lg,
                    right: AppSizes.lg,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppColors.success.withValues(alpha: 0.9)
                            : AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.white.withValues(alpha: 0.5),
                                  blurRadius: 3,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          AppText(
                            text: isAvailable ? 'Active' : 'Hidden',
                            size: 11,
                            color: AppColors.white,
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
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: name,
                    size: 18,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                  const SizedBox(height: AppSizes.md),
                  // Info Chips
                  Row(
                    children: [
                      if (price != null)
                        _InfoChip(
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          label: '\u20B9$price/hr',
                          iconColor: AppColors.primaryDarkGreen,
                          textColor: AppColors.primaryDarkGreen,
                          bgColor: AppColors.primaryDarkGreen.withValues(
                            alpha: 0.06,
                          ),
                        ),
                      if (price != null && openingTime.isNotEmpty)
                        const SizedBox(width: AppSizes.sm),
                      if (openingTime.isNotEmpty && closingTime.isNotEmpty)
                        _InfoChip(
                          icon: HugeIcons.strokeRoundedClock01,
                          label: '$openingTime \u2013 $closingTime',
                          iconColor: AppColors.textSecondaryLight,
                          textColor: AppColors.textSecondaryLight,
                          bgColor: AppColors.borderLight,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _toggleAvailability(context, isAvailable, name),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isAvailable
                                ? AppColors.error
                                : AppColors.primaryDarkGreen,
                            side: BorderSide(
                              color: isAvailable
                                  ? AppColors.error.withValues(alpha: 0.3)
                                  : AppColors.primaryDarkGreen.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                          icon: Icon(
                            isAvailable
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                          label: AppText(
                            text: isAvailable ? 'Hide' : 'Show',
                            size: 14,
                            weight: FontWeight.w600,
                            color: isAvailable
                                ? AppColors.error
                                : AppColors.primaryDarkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryDarkGreen,
                                Color(0xFF0FA968),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: onEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                            ),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedSettings01,
                              size: 18,
                              color: AppColors.white,
                            ),
                            label: const AppText(
                              text: 'Manage',
                              size: 14,
                              weight: FontWeight.w600,
                              color: AppColors.white,
                            ),
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

  void _toggleAvailability(
    BuildContext context,
    bool isCurrentlyAvailable,
    String groundName,
  ) {
    if (isCurrentlyAvailable) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedViewOff,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const AppText(
                text: 'Hide Ground?',
                size: 16,
                weight: FontWeight.w700,
              ),
            ],
          ),
          content: AppText(
            text:
                'Hiding "$groundName" will remove it from player search results. You can unhide it anytime.',
            size: 14,
            color: AppColors.textSecondaryLight,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: AppText(
                text: 'Cancel',
                size: 14,
                color: AppColors.textSecondaryLight,
                weight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                onAvailabilityChanged(false);
              },
              child: const AppText(
                text: 'Hide',
                size: 14,
                color: AppColors.error,
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

class _InfoChip extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm + 2,
        vertical: AppSizes.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: iconColor),
          const SizedBox(width: AppSizes.xs),
          AppText(
            text: label,
            size: 12,
            weight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String name;
  final String category;
  const _ImagePlaceholder({required this.name, required this.category});

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getPlaceholderGradient(category);
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSportIcon(category),
              size: 44,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: AppSizes.sm),
            AppText(
              text: name,
              size: 13,
              color: AppColors.white.withValues(alpha: 0.9),
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getPlaceholderGradient(String category) {
    switch (category.toLowerCase()) {
      case 'box_cricket':
      case 'cricket':
        return [const Color(0xFF1B5E20), const Color(0xFF43A047)];
      case 'football':
      case 'futsal':
        return [const Color(0xFF0D47A1), const Color(0xFF1E88E5)];
      case 'badminton':
      case 'tennis':
      case 'pickleball':
      case 'table_tennis':
        return [const Color(0xFFBF360C), const Color(0xFFE65100)];
      case 'volleyball':
        return [const Color(0xFF4A148C), const Color(0xFF7B1FA2)];
      case 'basketball':
        return [const Color(0xFFE65100), const Color(0xFFFF9800)];
      case 'swimming':
        return [const Color(0xFF006064), const Color(0xFF00ACC1)];
      case 'golf':
        return [const Color(0xFF1B5E20), const Color(0xFF66BB6A)];
      default:
        return [AppColors.primaryDarkGreen, const Color(0xFF43A047)];
    }
  }
}

class EmptyGrounds extends StatefulWidget {
  final VoidCallback onAdd;
  final String title;
  final String message;
  final String buttonLabel;

  const EmptyGrounds({
    super.key,
    required this.onAdd,
    this.title = 'No Grounds Yet',
    this.message =
        'Add a ground (one sport at a time) at this location to start accepting bookings.',
    this.buttonLabel = 'Add Ground',
  });

  @override
  State<EmptyGrounds> createState() => _EmptyGroundsState();
}

class _EmptyGroundsState extends State<EmptyGrounds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconBounce;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _iconBounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _iconBounce,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _iconBounce.value),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSizes.xxl),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCricketBat,
                  size: 56,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            AppText(
              text: widget.title,
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(height: AppSizes.sm),
            AppText(
              text: widget.message,
              size: 14,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppSizes.xxl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xxl,
                    vertical: AppSizes.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: AppText(
                  text: widget.buttonLabel,
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
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
      padding: const EdgeInsets.all(AppSizes.xl),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.lg),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.borderLight,
        highlightColor: AppColors.surfaceLight,
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
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
