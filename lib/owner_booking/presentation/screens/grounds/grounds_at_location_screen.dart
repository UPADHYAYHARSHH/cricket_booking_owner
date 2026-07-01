import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
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
            return const GroundsSkeleton();
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
              return EmptyGrounds(onAdd: _openAddFlow);
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
                  return GroundCard(
                    ground: ground,
                    onEdit: () => _openEditFlow(ground),
                    onAvailabilityChanged: (value) => context
                        .read<GroundCubit>()
                        .setGroundAvailability(
                          ground['id'] as String,
                          value,
                          locationId: widget.locationId,
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
