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
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      final minVersion = Platform.isAndroid
          ? svc.androidMinVersion
          : svc.iosMinVersion;
      if (minVersion.isEmpty) return false;
      final info = await PackageInfo.fromPlatform();
      return _isVersionLower(info.version, minVersion);
    } catch (_) {
      return false;
    }
  }

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

  Widget _buildStaggeredChild(int index, Widget child) {
    final start = (index * 0.15).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, _) {
        final progress = _staggerAnimation.value;
        final itemProgress = ((progress - start) / (end - start)).clamp(0.0, 1.0);
        final curvedProgress = Curves.easeOutCubic.transform(itemProgress);
        return Opacity(
          opacity: curvedProgress,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - curvedProgress)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const _DashboardSkeleton();
            }

            if (state is DashboardError) {
              return Center(
                child: AppText(text: state.message, color: AppColors.error),
              );
            }

            if (state is DashboardLoaded) {
              return RefreshIndicator(
                color: AppColors.primaryDarkGreen,
                onRefresh: () async {
                  await context.read<DashboardCubit>().fetchDashboardData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header and Overlapping Revenue Card
                      _buildStaggeredChild(0, Stack(
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
                                onLocationSelected: (locationId) => context
                                    .read<DashboardCubit>()
                                    .selectLocation(locationId),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildStaggeredChild(1, GestureDetector(
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
                            )),
                          ),
                        ],
                      )),
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildStaggeredChild(2, Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _AnimatedStatCard(
                              value: state.todayBookingsCount.toString(),
                              label: "Today's Bookings",
                              delay: 0,
                            ),
                            const SizedBox(width: 12),
                            _AnimatedStatCard(
                              value: state.pendingAcceptCount.toString(),
                              label: "Pending Accept",
                              delay: 100,
                            ),
                            const SizedBox(width: 12),
                            _AnimatedStatCard(
                              value: state.occupancyPercentage,
                              label: "Occupancy",
                              delay: 200,
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 32),

                      // Today's Slots Header
                      _buildStaggeredChild(3, Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              text: "Today's Slots",
                              color: AppColors.textPrimaryLight,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                            AppText(
                              text: DateFormat('EEE, d MMM').format(DateTime.now()),
                              color: AppColors.textSecondaryLight,
                              size: 13,
                              weight: FontWeight.w500,
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),

                      // Today's Slots List
                      if (state.todaySlots.isNotEmpty)
                        ...List.generate(state.todaySlots.length, (index) {
                          return _buildStaggeredChild(
                            4 + index,
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: TodayBookingCard(
                                booking: state.todaySlots[index] as Map<String, dynamic>,
                              ),
                            ),
                          );
                        })
                      else
                        _buildStaggeredChild(4, Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: AppColors.borderLight,
                                  ),
                                  const SizedBox(height: 12),
                                  AppText(
                                    text: "No bookings for today yet",
                                    color: AppColors.textSecondaryLight,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
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

/// Stat card with bounce-in animation
class _AnimatedStatCard extends StatefulWidget {
  final String value;
  final String label;
  final int delay;

  const _AnimatedStatCard({
    required this.value,
    required this.label,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: 300 + widget.delay), () {
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
    return Expanded(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: StatCard(
                value: widget.value,
                label: widget.label,
              ),
            ),
          );
        },
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
        backgroundColor: AppColors.surfaceLight,
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
                  color: AppColors.statusConfirmedBg,
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
                align: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AppText(
                text: 'A newer version of the app is required to continue. Please update to the latest version.',
                size: 13,
                color: AppColors.textSecondaryLight,
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
                      foregroundColor: AppColors.white,
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
                      color: AppColors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _closeApp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const AppText(
                    text: 'Close App',
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
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
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
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
        backgroundColor: AppColors.surfaceLight,
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
                    color: AppColors.statusPendingBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOrange.withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTools,
                      size: 40,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                text: "Under Maintenance",
                size: 20,
                weight: FontWeight.bold,
                align: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AppText(
                text: "We're working hard to improve your experience.\nPlease check back soon.",
                size: 13,
                color: AppColors.textSecondaryLight,
                align: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _closeApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGreen,
                    foregroundColor: AppColors.white,
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
                    color: AppColors.white,
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
          // Header skeleton
          Shimmer.fromColors(
            baseColor: AppColors.borderLight,
            highlightColor: AppColors.bgLight,
            child: Container(
              height: 200,
              width: double.infinity,
              color: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(height: 24),
          // Stats skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: AppColors.borderLight,
              highlightColor: AppColors.bgLight,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 80,
                      margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Title skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: AppColors.borderLight,
              highlightColor: AppColors.bgLight,
              child: Container(height: 16, width: 120, color: AppColors.surfaceLight),
            ),
          ),
          const SizedBox(height: 16),
          // Cards skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                3,
                (index) => Shimmer.fromColors(
                  baseColor: AppColors.borderLight,
                  highlightColor: AppColors.bgLight,
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
