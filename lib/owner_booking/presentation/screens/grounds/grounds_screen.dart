import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';

class GroundsScreen extends StatefulWidget {
  const GroundsScreen({super.key});

  @override
  State<GroundsScreen> createState() => _GroundsScreenState();
}

class _GroundsScreenState extends State<GroundsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroundCubit>().fetchOwnerGrounds();
  }

  Future<void> _openAddFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroundFormFlow()),
    );
    // GroundFormFlow refreshes the list itself on save; no extra call needed.
  }

  Future<void> _openEditFlow(Map<String, dynamic> ground) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroundFormFlow(groundData: ground)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppText(
            text: 'My Grounds', size: 18, weight: FontWeight.w700),
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
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 48,
                      color: AppColors.error),
                  const SizedBox(height: 12),
                  AppText(
                      text: state.message,
                      color: AppColors.error,
                      size: 14),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<GroundCubit>().fetchOwnerGrounds(),
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
                  context.read<GroundCubit>().fetchOwnerGrounds(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.grounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ground =
                      state.grounds[index] as Map<String, dynamic>;
                  return _GroundCard(
                    ground: ground,
                    onEdit: () => _openEditFlow(ground),
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

  const _GroundCard({required this.ground, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = ground['name'] as String? ?? 'Unknown Ground';
    final address = ground['address'] as String? ?? '';
    final imageUrl = ground['imageUrl'] as String?;
    final isVerified = ground['is_verified'] == true;
    final categories = (ground['categories'] as List?)
            ?.map((e) => e.toString())
            .join(', ') ??
        '';
    final price = ground['price_per_hour'];
    final openingTime = ground['opening_time'] as String? ?? '';
    final closingTime = ground['closing_time'] as String? ?? '';

    return Container(
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
          // Image + overlay badges
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ImagePlaceholder(name: name),
                      )
                    : _ImagePlaceholder(name: name),
                // Verified / Pending badge on image
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.primaryDarkGreen
                          : AppColors.accentOrange,
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
                // Edit button on image
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined,
                              size: 14,
                              color: AppColors.primaryDarkGreen),
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
                AppText(
                    text: name,
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(0xFF212121)),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText(
                    text: _formatCategories(categories),
                    size: 12,
                    color: AppColors.primaryDarkGreen,
                    weight: FontWeight.w600,
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 13,
                          color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText(
                            text: address,
                            size: 12,
                            color: Colors.grey),
                      ),
                    ],
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
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 13,
                          color: Colors.grey),
                      const SizedBox(width: 4),
                      AppText(
                        text: '$openingTime – $closingTime',
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                    const Spacer(),
                    // Quick edit button at bottom right
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryDarkGreen.withOpacity(0.2),
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategories(String raw) => raw
      .split(',')
      .map((s) => s
          .trim()
          .split('_')
          .map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' '))
      .join(' • ');
}

// ---------------------------------------------------------------------------
// Image placeholder
// ---------------------------------------------------------------------------

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
            AppText(
              text: name,
              size: 13,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

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
              text:
                  'Add your first ground to start accepting bookings from players.',
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

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
