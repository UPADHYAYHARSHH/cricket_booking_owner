import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/grounds/grounds_at_location_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_documents_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_screen.dart';

/// Top-level screen for the "Grounds" tab: an owner picks one of their
/// venue Locations (or adds a new one) before managing the grounds at it.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().fetchOwnerLocations();
  }

  Future<void> _openAddLocation() async {
    final newLocationId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const LocationFormScreen()),
    );
    if (newLocationId == null || !mounted) return;

    // Collect property/ownership documents for this venue. The location
    // stays in "Pending verification" until these are reviewed — grounds
    // can't be added until then (see _openGrounds).
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDocumentsScreen(locationId: newLocationId),
      ),
    );
  }

  Future<void> _openEditLocation(Map<String, dynamic> location) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationFormScreen(locationData: location)),
    );
  }

  Future<void> _openDocuments(Map<String, dynamic> location) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDocumentsScreen(
          locationId: location['id'] as String,
          locationData: location,
        ),
      ),
    );
    if (!mounted) return;
    context.read<LocationCubit>().fetchOwnerLocations();
  }

  void _openGrounds(Map<String, dynamic> location) {
    if (location['documents_verified'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This location is pending verification. You'll be able to add sports/grounds once it's verified.",
          ),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundsAtLocationScreen(
          locationId: location['id'] as String,
          locationAddress: location['address'] as String? ?? 'Location',
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
        title: const AppText(text: 'My Locations', size: 18, weight: FontWeight.w700),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Add new location',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 24,
              color: AppColors.primaryDarkGreen,
            ),
            onPressed: _openAddLocation,
          ),
        ],
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is LocationLoading || state is LocationInitial) {
            return const _LocationsSkeleton();
          }

          if (state is LocationError) {
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
                    onPressed: () => context.read<LocationCubit>().fetchOwnerLocations(),
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

          if (state is LocationLoaded) {
            if (state.locations.isEmpty) {
              return _EmptyLocations(onAdd: _openAddLocation);
            }

            return RefreshIndicator(
              color: AppColors.primaryDarkGreen,
              onRefresh: () => context.read<LocationCubit>().fetchOwnerLocations(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final location = state.locations[index];
                  return _LocationCard(
                    location: location,
                    onTap: () => _openGrounds(location),
                    onEdit: () => _openEditLocation(location),
                    onDocuments: () => _openDocuments(location),
                    onActiveChanged: (value) => context.read<LocationCubit>().updateLocation(
                          locationId: location['id'] as String,
                          data: {'is_active': value},
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
        onPressed: _openAddLocation,
        backgroundColor: AppColors.primaryDarkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const AppText(
          text: 'Add Location',
          size: 14,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDocuments;
  final ValueChanged<bool> onActiveChanged;

  const _LocationCard({
    required this.location,
    required this.onTap,
    required this.onEdit,
    required this.onDocuments,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final address = location['address'] as String? ?? '';
    final city = location['city'] as String? ?? '';
    final isActive = location['is_active'] != false;
    final isVerified = location['documents_verified'] == true;
    final hasDocuments = location['property_document_url'] != null;

    return Opacity(
      opacity: !isVerified ? 0.85 : (isActive ? 1 : 0.6),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      size: 22,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: address.isEmpty ? 'Unnamed location' : address,
                                size: 15,
                                weight: FontWeight.w700,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const AppText(
                                  text: 'Pending Verification',
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                            ] else if (!isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const AppText(
                                  text: 'Inactive',
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (city.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          AppText(text: city, size: 12, color: Colors.grey),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryDarkGreen),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: isActive ? 'Active — visible to players' : 'Disabled — hidden from players',
                  size: 12,
                  weight: FontWeight.w600,
                  color: isActive ? AppColors.primaryDarkGreen : Colors.grey,
                ),
                Switch(
                  value: isActive,
                  activeColor: AppColors.primaryDarkGreen,
                  onChanged: onActiveChanged,
                ),
              ],
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onDocuments,
              child: Row(
                children: [
                  Icon(
                    hasDocuments ? Icons.description : Icons.upload_file_outlined,
                    size: 14,
                    color: hasDocuments ? AppColors.primaryDarkGreen : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    text: hasDocuments ? 'Documents submitted' : 'Add venue documents',
                    size: 12,
                    weight: FontWeight.w600,
                    color: hasDocuments ? AppColors.primaryDarkGreen : Colors.grey,
                  ),
                ],
              ),
            ),
            if (!isVerified) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_top, size: 14, color: AppColors.accentOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        text: hasDocuments
                            ? "We're reviewing your documents. You'll be able to add sports/grounds once verified."
                            : 'Submit venue documents to get this location verified before adding sports/grounds.',
                        size: 11,
                        color: const Color(0xFF795548),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLocations({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              size: 72,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const AppText(
              text: 'No Locations Yet',
              size: 20,
              weight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
            const SizedBox(height: 8),
            const AppText(
              text: 'Add your first venue location, then add grounds to it.',
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
                text: 'Add Location',
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

class _LocationsSkeleton extends StatelessWidget {
  const _LocationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
