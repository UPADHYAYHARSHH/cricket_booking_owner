import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/revenue_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/stat_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/dashboard/widgets/today_booking_card.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/revenue/revenue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());
  }

  Future<void> _runStartupChecks() async {
    if (!mounted) return;
    final needsUpdate = await _needsForceUpdate();
    if (!mounted) return;
    if (needsUpdate) {
      _showForceUpdateDialog(context);
    } else if (AppConfigService.instance.ownerAppMaintenance) {
      _showMaintenanceDialog(context);
    }
  }

  Future<bool> _needsForceUpdate() async {
    try {
      final svc = AppConfigService.instance;
      final minVersion = Platform.isAndroid ? svc.androidMinVersion : svc.iosMinVersion;
      if (minVersion.isEmpty) return false;
      final info = await PackageInfo.fromPlatform();
      return _isVersionLower(info.version, minVersion);
    } catch (_) {
      return false;
    }
  }

  /// Returns true when [current] is strictly less than [minimum].
  /// Compares dot-separated integer segments (e.g. "1.0.3" < "1.1.0").
  bool _isVersionLower(String current, String minimum) {
    final cur = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final min = minimum.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = cur.length > min.length ? cur.length : min.length;
    for (int i = 0; i < len; i++) {
      final c = i < cur.length ? cur[i] : 0;
      final m = i < min.length ? min[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  void _showForceUpdateDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _ForceUpdateDialog(
        storeUrl: Platform.isAndroid
            ? AppConfigService.instance.androidStoreUrl
            : AppConfigService.instance.iosStoreUrl,
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const _MaintenanceDialog(),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const AppText(text: 'Log Out', size: 16, weight: FontWeight.w700),
        content: const AppText(
          text: 'Are you sure you want to log out?',
          size: 14,
          color: Colors.black54,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: AppText(
              text: 'Cancel',
              size: 14,
              color: Colors.grey.shade600,
              weight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ctx.read<AuthCubit>().logout();
              Navigator.pushNamedAndRemoveUntil(ctx, '/', (route) => false);
            },
            child: const AppText(
              text: 'Log Out',
              size: 14,
              color: Color(0xFFE53935),
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const _DashboardSkeleton();
            }

            if (state is DashboardError) {
              return Center(
                child: AppText(
                  text: state.message,
                  color: AppColors.error,
                ),
              );
            }

            if (state is DashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header and Overlapping Revenue Card
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            DashboardHeader(
                              ownerName: state.ownerName,
                              venueName: state.venueName,
                              activeCourts: state.activeCourts,
                              locations: state.locations,
                              selectedLocationId: state.selectedLocationId,
                              onLocationSelected: (locationId) =>
                                  context.read<DashboardCubit>().selectLocation(locationId),
                              onLogout: () => _confirmLogout(context),
                            ),
                            const SizedBox(height: 110), // Space for revenue card overlap
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => getIt<RevenueCubit>(),
                                  child: const RevenueScreen(),
                                ),
                              ),
                            ),
                            child: RevenueCard(
                              amount: state.todayRevenue,
                              percentageChange: state.revenueChangeLabel,
                              bookingsCount: state.todayBookingsCount.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          StatCard(value: state.todayBookingsCount.toString(), label: "Today's Bookings"),
                          const SizedBox(width: 12),
                          StatCard(value: state.pendingAcceptCount.toString(), label: "Pending Accept"),
                          const SizedBox(width: 12),
                          StatCard(value: state.occupancyPercentage, label: "Occupancy"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Today's Slots Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: "Today's Slots",
                            color: Colors.black87,
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                          AppText(
                            text: DateFormat('EEE, d MMM').format(DateTime.now()),
                            color: Colors.grey.shade500,
                            size: 13,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Today's Slots List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: state.todaySlots.isNotEmpty
                          ? Column(
                              children: state.todaySlots.map((slot) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TodayBookingCard(
                                    booking: slot as Map<String, dynamic>,
                                  ),
                                );
                              }).toList(),
                            )
                          : const AppText(
                              text: "No bookings for today yet.",
                              color: Colors.grey,
                            ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          ),
        ),
      );
  }
}

class _ForceUpdateDialog extends StatelessWidget {
  final String storeUrl;
  const _ForceUpdateDialog({required this.storeUrl});

  void _openStore() async {
    if (storeUrl.isEmpty) return;
    final uri = Uri.tryParse(storeUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload02,
                    size: 40,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                text: 'Update Required',
                size: 20,
                weight: FontWeight.bold,
                color: Colors.black87,
                align: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AppText(
                text: 'A newer version of the app is required to continue. Please update to the latest version.',
                size: 13,
                color: Colors.grey.shade500,
                align: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (storeUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const AppText(
                      text: 'Update Now',
                      size: 15,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _closeApp,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: AppText(
                    text: 'Close App',
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceDialog extends StatefulWidget {
  const _MaintenanceDialog();

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF57C00).withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTools,
                      size: 40,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                text: "Under Maintenance",
                size: 20,
                weight: FontWeight.bold,
                color: Colors.black87,
                align: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AppText(
                text:
                    "We're working hard to improve your experience.\nPlease check back soon.",
                size: 13,
                color: Colors.grey.shade500,
                align: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _closeApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const AppText(
                    text: "Close App",
                    size: 15,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 16, width: 120, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (index) => Container(width: 100, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

