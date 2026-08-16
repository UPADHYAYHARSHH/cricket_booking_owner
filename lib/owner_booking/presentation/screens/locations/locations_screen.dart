import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/grounds/grounds_at_location_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_documents_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_screen.dart';

/// Location management screen, reached from the "Grounds" tab's app bar:
/// lets an owner add/edit/delete venue Locations and manage their
/// documents. Tapping a location card still opens its grounds directly.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().fetchOwnerLocations();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutCubic,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _openAddLocation() async {
    final newLocationId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const LocationFormScreen()),
    );
    if (newLocationId == null || !mounted) return;

    // Collect property/ownership documents for this venue. The location
    // stays "Pending Approval" until the admin reviews it, but the owner
    // can add grounds right away — approval only gates user-facing visibility.
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
      MaterialPageRoute(
        builder: (_) => LocationFormScreen(locationData: location),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> location) async {
    final address = location['address'] as String? ?? 'this location';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            const AppText(
              text: 'Delete Location',
              size: 18,
              weight: FontWeight.w700,
            ),
          ],
        ),
        content: AppText(
          text:
              'Delete "$address"? Its grounds will stop showing to players immediately. '
              'This can be reversed by support if needed — booking history is kept.',
          size: 14,
          color: AppColors.textSecondaryLight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText(
              text: 'Cancel',
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText(
              text: 'Delete',
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<LocationCubit>().deleteLocation(
      location['id'] as String,
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
    final isVerified = location['documents_verified'] == true;
    if (!isVerified) {
      // Show message that location needs verification first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This location is pending admin approval. '
            'You can add grounds once it is verified.',
          ),
          backgroundColor: AppColors.accentOrange,
          duration: const Duration(seconds: 4),
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
          isVerified: isVerified,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppSizes.lg,
            right: AppSizes.lg,
            bottom: AppSizes.lg,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                const Expanded(
                  child: AppText(
                    text: 'Manage Locations',
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _openAddLocation,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 22,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  Container(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  const AppText(
                    text: 'Something went wrong',
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  AppText(
                    text: state.message,
                    color: AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  TextButton(
                    onPressed: () =>
                        context.read<LocationCubit>().fetchOwnerLocations(),
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
              onRefresh: () async =>
                  context.read<LocationCubit>().fetchOwnerLocations(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.xl),
                itemCount: state.locations.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.lg),
                itemBuilder: (context, index) {
                  final location = state.locations[index];
                  return AnimatedBuilder(
                    animation: _staggerAnimation,
                    builder: (context, child) {
                      final delay = (index * 0.15).clamp(0.0, 0.6);
                      final itemProgress =
                          ((_staggerAnimation.value - delay) / (1.0 - delay))
                              .clamp(0.0, 1.0);
                      return Opacity(
                        opacity: itemProgress,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - itemProgress)),
                          child: child,
                        ),
                      );
                    },
                    child: _LocationCard(
                      location: location,
                      onTap: () => _openGrounds(location),
                      onEdit: () => _openEditLocation(location),
                      onDelete: () => _confirmDelete(location),
                      onDocuments: () => _openDocuments(location),
                      onActiveChanged: (value) =>
                          context.read<LocationCubit>().updateLocation(
                            locationId: location['id'] as String,
                            data: {'is_active': value},
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
        heroTag: 'locations_add_location',
        onPressed: _openAddLocation,
        backgroundColor: AppColors.primaryDarkGreen,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        ),
        icon: const Icon(Icons.add, size: 22),
        label: const AppText(
          text: 'Add Location',
          size: 14,
          weight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDocuments;
  final ValueChanged<bool> onActiveChanged;

  const _LocationCard({
    required this.location,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDocuments,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final address = location['address'] as String? ?? '';
    final city = location['city'] as String? ?? '';
    final isActive = location['is_active'] != false;
    final isVerified = location['documents_verified'] == true;
    final isRejected = location['rejection_reason'] != null && !isVerified;
    final rejectionReason = location['rejection_reason'] as String? ?? '';
    final hasDocuments = location['property_document_url'] != null;

    final accentColor = isVerified
        ? AppColors.primaryDarkGreen
        : isRejected
        ? Colors.red
        : isActive
        ? AppColors.accentOrange
        : AppColors.borderLight;

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              GestureDetector(
                onTap: onTap,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 22,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: (location['name'] as String?)?.isNotEmpty == true
                                ? location['name'] as String
                                : '---',
                            size: 15,
                            weight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            AppText(
                              text: address,
                              size: 12,
                              color: AppColors.textSecondaryLight,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primaryDarkGreen,
                              ),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.slotAvailableBg
                      : isRejected
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.statusPendingBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.primaryDarkGreen.withValues(alpha: 0.2)
                        : isRejected
                        ? Colors.red.withValues(alpha: 0.3)
                        : AppColors.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppColors.primaryDarkGreen
                            : isRejected
                            ? Colors.red
                            : AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs + 2),
                    AppText(
                      text: isVerified
                          ? (isActive ? 'Verified & Active' : 'Verified')
                          : isRejected
                          ? 'Rejected'
                          : 'Pending Approval',
                      size: 11,
                      weight: FontWeight.w600,
                      color: isVerified
                          ? AppColors.primaryDarkGreen
                          : isRejected
                          ? Colors.red
                          : AppColors.accentOrange,
                    ),
                  ],
                ),
              ),
              if (!isActive) ...[
                const SizedBox(height: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const AppText(
                    text: 'Inactive — hidden from players',
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.md),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.borderLight.withValues(alpha: 0),
                      AppColors.borderLight,
                      AppColors.borderLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Bottom row: toggle + documents
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 16,
                          color: isActive
                              ? AppColors.primaryDarkGreen
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        AppText(
                          text: isActive ? 'Active' : 'Disabled',
                          size: 12,
                          weight: FontWeight.w600,
                          color: isActive
                              ? AppColors.primaryDarkGreen
                              : AppColors.textSecondaryLight,
                        ),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primaryDarkGreen,
                          onChanged: onActiveChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.lg),
                  GestureDetector(
                    onTap: onDocuments,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.red.withValues(alpha: 0.08)
                            : hasDocuments
                            ? AppColors.primaryDarkGreen.withValues(alpha: 0.08)
                            : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color: isRejected
                              ? Colors.red.withValues(alpha: 0.2)
                              : hasDocuments
                              ? AppColors.primaryDarkGreen.withValues(alpha: 0.2)
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRejected
                                ? Icons.refresh
                                : hasDocuments
                                ? Icons.description
                                : Icons.upload_file_outlined,
                            size: 14,
                            color: isRejected
                                ? Colors.red
                                : hasDocuments
                                ? AppColors.primaryDarkGreen
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          AppText(
                            text: isRejected
                                ? 'Re-upload'
                                : hasDocuments
                                ? 'View Docs'
                                : 'Add Docs',
                            size: 11,
                            weight: FontWeight.w600,
                            color: isRejected
                                ? Colors.red
                                : hasDocuments
                                ? AppColors.primaryDarkGreen
                                : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Pending/Rejected approval notice
              if (!isVerified) ...[
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isRejected
                          ? [
                              Colors.red.withValues(alpha: 0.05),
                              Colors.red.withValues(alpha: 0.02),
                            ]
                          : [
                              AppColors.statusPendingBg,
                              AppColors.statusPendingBg.withValues(alpha: 0.5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: isRejected
                          ? Colors.red.withValues(alpha: 0.2)
                          : AppColors.accentOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.xs),
                            decoration: BoxDecoration(
                              color: isRejected
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : AppColors.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusXs,
                              ),
                            ),
                            child: Icon(
                              isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                              size: 14,
                              color: isRejected ? Colors.red : AppColors.accentOrange,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: AppText(
                              text: isRejected
                                  ? (rejectionReason.isNotEmpty
                                      ? rejectionReason
                                      : 'Your documents were rejected. Please re-upload and submit again.')
                                  : hasDocuments
                                  ? "Your location is awaiting admin approval. You can add sports/grounds now — they'll go live once the location is approved."
                                  : "Submit venue documents for faster approval. You can add sports/grounds now while it's reviewed.",
                              size: 11,
                              color: isRejected
                                  ? Colors.red.shade700
                                  : const Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                      if (isRejected) ...[
                        const SizedBox(height: AppSizes.sm),
                        AppText(
                          text: 'Tap "Re-upload" to update your documents and resubmit.',
                          size: 10,
                          color: Colors.red.withValues(alpha: 0.7),
                          weight: FontWeight.w500,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
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
            Container(
              padding: const EdgeInsets.all(AppSizes.xxl),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 64,
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            const AppText(
              text: 'No Locations Yet',
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(height: AppSizes.sm),
            const AppText(
              text: 'Add your first venue location, then add\ngrounds to it.',
              size: 14,
              color: AppColors.textSecondaryLight,
              align: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xxl + 4),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: AppColors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xxl,
                  vertical: AppSizes.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const AppText(
                text: 'Add Location',
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.white,
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
      padding: const EdgeInsets.all(AppSizes.xl),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.lg),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.borderLight,
        highlightColor: AppColors.white,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
      ),
    );
  }
}
