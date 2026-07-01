import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/locations_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/ground_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';

/// The "Grounds" tab: pick a location from the dropdown (or leave it on
/// "All Locations") and see the grounds for that selection. Location
/// management (add/edit/delete/documents) lives in [LocationsScreen],
/// reachable from the app bar action here.
class GroundsScreen extends StatefulWidget {
  const GroundsScreen({super.key});

  @override
  State<GroundsScreen> createState() => _GroundsScreenState();
}

class _GroundsScreenState extends State<GroundsScreen> {
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().fetchOwnerLocations();
    _fetchGrounds();
  }

  void _fetchGrounds() {
    if (_selectedLocationId == null) {
      context.read<GroundCubit>().fetchOwnerGrounds();
    } else {
      context.read<GroundCubit>().fetchGroundsForLocation(_selectedLocationId!);
    }
  }

  void _onLocationSelected(String? locationId) {
    setState(() => _selectedLocationId = locationId);
    _fetchGrounds();
  }

  Future<void> _openManageLocations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationsScreen()),
    );
    if (!mounted) return;
    context.read<LocationCubit>().fetchOwnerLocations();
    _fetchGrounds();
  }

  Future<void> _openAddFlow(List<Map<String, dynamic>> locations) async {
    if (locations.isEmpty) {
      await _openManageLocations();
      return;
    }

    var locationId = _selectedLocationId;
    if (locationId == null) {
      if (locations.length == 1) {
        locationId = locations.first['id'] as String;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a location above first, then add a ground to it.')),
        );
        return;
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroundFormFlow(locationId: locationId!)),
    );
    if (!mounted) return;
    _fetchGrounds();
  }

  Future<void> _openEditFlow(Map<String, dynamic> ground) async {
    final locationId = ground['location_id'] as String?;
    if (locationId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundFormFlow(locationId: locationId, groundData: ground),
      ),
    );
    if (!mounted) return;
    _fetchGrounds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppText(text: 'Grounds', size: 18, weight: FontWeight.w700),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Manage locations',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              size: 22,
              color: AppColors.primaryDarkGreen,
            ),
            onPressed: _openManageLocations,
          ),
        ],
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, locationState) {
          final locations =
              locationState is LocationLoaded ? locationState.locations : <Map<String, dynamic>>[];

          return Column(
            children: [
              if (locations.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: LocationDropdown(
                    locations: locations,
                    selectedLocationId: _selectedLocationId,
                    onSelected: _onLocationSelected,
                  ),
                ),
              Expanded(
                child: BlocBuilder<GroundCubit, GroundState>(
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
                                icon: HugeIcons.strokeRoundedAlert02,
                                size: 48,
                                color: AppColors.error),
                            const SizedBox(height: 12),
                            AppText(text: state.message, color: AppColors.error, size: 14),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _fetchGrounds,
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
                        return EmptyGrounds(
                          onAdd: () => _openAddFlow(locations),
                          title: _selectedLocationId == null ? 'No Grounds Yet' : 'No Grounds Here Yet',
                          message: locations.isEmpty
                              ? 'Add a venue location first, then add grounds to it.'
                              : 'Add a ground (one sport at a time) to start accepting bookings.',
                          buttonLabel: locations.isEmpty ? 'Add Location' : 'Add Ground',
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.primaryDarkGreen,
                        onRefresh: () async => _fetchGrounds(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.grounds.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ground = state.grounds[index] as Map<String, dynamic>;
                            return GroundCard(
                              ground: ground,
                              onEdit: () => _openEditFlow(ground),
                              onAvailabilityChanged: (value) =>
                                  context.read<GroundCubit>().setGroundAvailability(
                                        ground['id'] as String,
                                        value,
                                        locationId: _selectedLocationId,
                                      ),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFlow(
          context.read<LocationCubit>().state is LocationLoaded
              ? (context.read<LocationCubit>().state as LocationLoaded).locations
              : <Map<String, dynamic>>[],
        ),
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
