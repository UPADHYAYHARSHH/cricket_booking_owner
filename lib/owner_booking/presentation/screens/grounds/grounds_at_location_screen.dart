import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';

/// Lists the single-sport grounds belonging to one Location, and lets the
/// owner add a new ground (one sport at a time) at that location.
class GroundsAtLocationScreen extends StatefulWidget {
  final String locationId;
  final String locationAddress;

  const GroundsAtLocationScreen({
    super.key,
    required this.locationId,
    required this.locationAddress,
  });

  @override
  State<GroundsAtLocationScreen> createState() => _GroundsAtLocationScreenState();
}

class _GroundsAtLocationScreenState extends State<GroundsAtLocationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroundCubit>().fetchGroundsForLocation(widget.locationId);
  }

  Future<void> _openAddFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundFormFlow(locationId: widget.locationId),
      ),
    );
  }

  Future<void> _openEditFlow(Map<String, dynamic> ground) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundFormFlow(
          locationId: widget.locationId,
          groundData: ground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDarkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: widget.locationAddress,
          size: 15,
          weight: FontWeight.w700,
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Add new ground',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 24,
              color: AppColors.primaryDarkGreen,
            ),
            onPressed: _openAddFlow,
          ),
        ],
      ),
      body: BlocBuilder<GroundCubit, GroundState>(
        builder: (context, state) {
          if (state is GroundLoading || state is GroundInitial) {
            return const _GroundsSkeleton();
          }

          if (state is GroundError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  AppText(text: state.message, color: AppColors.error, size: 14),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<GroundCubit>().fetchGroundsForLocation(widget.locationId),
                    child: const AppText(
                      text: 'Retry',
                      color: AppColors.primaryDarkGreen,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is GroundLoaded) {
            if (state.grounds.isEmpty) {
              return _EmptyGrounds(onAdd: _openAddFlow);
            }

            return RefreshIndicator(
              color: AppColors.primaryDarkGreen,
              onRefresh: () =>
                  context.read<GroundCubit>().fetchGroundsForLocation(widget.locationId),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.grounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ground = state.grounds[index] as Map<String, dynamic>;
                  return _GroundCard(
                    ground: ground,
                    onEdit: () => _openEditFlow(ground),
                    onAvailabilityChanged: (value) => context
                        .read<GroundCubit>()
                        .setGroundAvailability(ground['id'] as String, value, widget.locationId),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFlow,
        backgroundColor: AppColors.primaryDarkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const AppText(
          text: 'Add Ground',
          size: 14,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ground card
// ---------------------------------------------------------------------------

class _GroundCard extends StatelessWidget {
  final Map<String, dynamic> ground;
  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailabilityChanged;

  const _GroundCard({
    required this.ground,
    required this.onEdit,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = ground['name'] as String? ?? 'Unknown Ground';
    final imageUrl = ground['imageUrl'] as String?;
    final isVerified = ground['is_verified'] == true;
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isVerified ? AppColors.primaryDarkGreen : AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      text: isVerified ? '✓ Verified' : 'Pending Review',
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryDarkGreen),
                          SizedBox(width: 4),
                          AppText(
                            text: 'Edit',
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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

class _EmptyGrounds extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGrounds({required this.onAdd});

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
            const AppText(
              text: 'No Grounds Yet',
              size: 20,
              weight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
            const SizedBox(height: 8),
            const AppText(
              text: 'Add a ground (one sport at a time) at this location to start accepting bookings.',
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
              label: const AppText(
                text: 'Add Ground',
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

class _GroundsSkeleton extends StatelessWidget {
  const _GroundsSkeleton();

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
