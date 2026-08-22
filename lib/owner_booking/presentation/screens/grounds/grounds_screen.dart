import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/locations_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/ground_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';

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
    _selectedLocationId = SharedPrefsService.instance.selectedLocationId;
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
    SharedPrefsService.instance.setSelectedLocationId(locationId);
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
          const SnackBar(
            content: Text(
              'Pick a location above first, then add a ground to it.',
            ),
          ),
        );
        return;
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundFormFlow(locationId: locationId!),
      ),
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
        builder: (_) =>
            GroundFormFlow(locationId: locationId, groundData: ground),
      ),
    );
    if (!mounted) return;
    _fetchGrounds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, locationState) {
          final locations = locationState is LocationLoaded
              ? locationState.locations
              : <Map<String, dynamic>>[];

          return BlocBuilder<GroundCubit, GroundState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: AppColors.primaryDarkGreen,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: locations.length > 1 ? 140.0 : null,
                    title: locations.length > 1
                        ? null
                        : const AppText(
                            text: 'Grounds',
                            size: 18,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                    flexibleSpace: locations.length > 1
                        ? FlexibleSpaceBar(
                            background: _buildGreenHeader(context, locations),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
                              ),
                            ),
                          ),
                    actions: [
                      IconButton(
                        tooltip: 'Add ground',
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 22,
                          color: AppColors.white,
                        ),
                        onPressed: () => _openAddFlow(locations),
                      ),
                    ],
                  ),
                  if (state is GroundLoading || state is GroundInitial)
                    const SliverPadding(
                      padding: EdgeInsets.only(top: AppSizes.xl),
                      sliver: SliverToBoxAdapter(child: GroundsSkeleton()),
                    )
                  else if (state is GroundError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSizes.xxl),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.08,
                                  ),
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
                                onPressed: _fetchGrounds,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDarkGreen,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.xxl,
                                    vertical: AppSizes.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull,
                                    ),
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
                      ),
                    )
                  else if (state is GroundLoaded && state.grounds.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyGrounds(
                        onAdd: () => _openAddFlow(locations),
                        title: _selectedLocationId == null
                            ? 'No Grounds Yet'
                            : 'No Grounds Here Yet',
                        message: locations.isEmpty
                            ? 'Add a venue location first, then add grounds to it.'
                            : 'Add a ground (one sport at a time) to start accepting bookings.',
                        buttonLabel: locations.isEmpty
                            ? 'Add Location'
                            : 'Add Ground',
                      ),
                    )
                  else if (state is GroundLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final ground = state.grounds[index] as Map<String, dynamic>;
                          
                          // Extract images from location
                          List<String> locImages = [];
                          final groundLocationId = ground['location_id'] as String?;
                          if (groundLocationId != null && locations.isNotEmpty) {
                            try {
                              final loc = locations.firstWhere((l) => l['id'] == groundLocationId);
                              if (loc['location_images'] != null) {
                                final imgs = loc['location_images'] as List;
                                locImages = imgs.map((e) => e['image_url'].toString()).toList();
                              }
                            } catch (_) {}
                          }

                          return _StaggeredGroundCard(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.lg,
                              ),
                              child: GroundCard(
                                ground: ground,
                                images: locImages,
                                onEdit: () => _openEditFlow(ground),
                                onAvailabilityChanged: (value) => context
                                    .read<GroundCubit>()
                                    .setGroundAvailability(
                                      ground['id'] as String,
                                      value,
                                      locationId: _selectedLocationId,
                                    ),
                              ),
                            ),
                          );
                        }, childCount: state.grounds.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGreenHeader(
    BuildContext context,
    List<Map<String, dynamic>> locations,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
        ),
      ),
      child: SafeArea(
        child: locations.length > 1
            ? Container(
                padding: const EdgeInsets.only(
                  top: AppSizes.xl + 4,
                  left: AppSizes.xl,
                  right: AppSizes.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppText(
                      text: 'Grounds',
                      size: 20,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    LocationDropdown(
                      locations: locations,
                      selectedLocationId: _selectedLocationId,
                      onSelected: _onLocationSelected,
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
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
