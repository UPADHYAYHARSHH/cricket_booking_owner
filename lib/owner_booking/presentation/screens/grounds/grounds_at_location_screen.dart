import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/ground_card.dart';

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
      backgroundColor: AppColors.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkGreen,
                Color(0xFF0FA968),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: AppText(
              text: widget.locationAddress,
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.white,
              maxLines: 1,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Add new ground',
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 24,
                  color: AppColors.white,
                ),
                onPressed: _openAddFlow,
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<GroundCubit, GroundState>(
        builder: (context, state) {
          if (state is GroundLoading || state is GroundInitial) {
            return const GroundsSkeleton();
          }

          if (state is GroundError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppText(
                      text: state.message,
                      color: AppColors.error,
                      size: 14,
                    ),
                    const SizedBox(height: AppSizes.xl),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<GroundCubit>().fetchGroundsForLocation(widget.locationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDarkGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xxl,
                          vertical: AppSizes.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const AppText(
                        text: 'Retry',
                        color: AppColors.white,
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is GroundLoaded) {
            if (state.grounds.isEmpty) {
              return EmptyGrounds(onAdd: _openAddFlow);
            }

            return RefreshIndicator(
              color: AppColors.primaryDarkGreen,
              onRefresh: () =>
                  context.read<GroundCubit>().fetchGroundsForLocation(widget.locationId),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.xl),
                itemCount: state.grounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.lg),
                itemBuilder: (context, index) {
                  final ground = state.grounds[index] as Map<String, dynamic>;
                  return _StaggeredGroundCard(
                    index: index,
                    child: GroundCard(
                      ground: ground,
                      onEdit: () => _openEditFlow(ground),
                      onAvailabilityChanged: (value) => context
                          .read<GroundCubit>()
                          .setGroundAvailability(
                            ground['id'] as String,
                            value,
                            locationId: widget.locationId,
                          ),
                    ),
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
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const AppText(
          text: 'Add Ground',
          size: 14,
          weight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Wraps each ground card with a staggered fade+slide entrance animation.
class _StaggeredGroundCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredGroundCard({required this.index, required this.child});

  @override
  State<_StaggeredGroundCard> createState() => _StaggeredGroundCardState();
}

class _StaggeredGroundCardState extends State<_StaggeredGroundCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
