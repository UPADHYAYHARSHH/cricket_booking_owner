import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

class PendingApprovalCard extends StatefulWidget {
  final Map<String, dynamic> booking;

  const PendingApprovalCard({super.key, required this.booking});

  @override
  State<PendingApprovalCard> createState() => _PendingApprovalCardState();
}

class _PendingApprovalCardState extends State<PendingApprovalCard> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActionLoading = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTimer();
  }

  @override
  void didUpdateWidget(PendingApprovalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking['status'] != widget.booking['status'] ||
        oldWidget.booking['created_at'] != widget.booking['created_at']) {
      _checkAndStartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _parseUtcToLocal(dynamic value) {
    if (value == null) return null;
    String s = value.toString().trim();
    if (s.isEmpty) return null;
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }
    if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:?\d{2}$').hasMatch(s)) {
      s = '${s}Z';
    }
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.tryParse(value.toString())?.toLocal();
    }
  }

  void _checkAndStartTimer() {
    _timer?.cancel();
    final createdAt = _parseUtcToLocal(widget.booking['created_at']);
    if (createdAt != null) {
      final deadline = createdAt.add(const Duration(minutes: 45));
      final diff = deadline.difference(DateTime.now()).inSeconds;
      _remainingSeconds = diff > 0 ? diff : 0;
    } else {
      _remainingSeconds = 2700;
    }

    if (_remainingSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            t.cancel();
            final id = widget.booking['id']?.toString();
            if (id != null) {
              context.read<BookingsCubit>().expireBooking(id);
              try {
                context.read<DashboardCubit>().fetchDashboardData();
              } catch (_) {}
            }
          }
        });
      });
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _simplifyPeriod(String period) {
    if (!period.contains(',')) return period;

    final parts = period.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return period;

    List<String> merged = [];
    String? currentStart;
    String? currentEnd;

    for (final p in parts) {
      final range = p.split('-').map((e) => e.trim()).toList();
      if (range.length != 2) return period;

      final start = range[0];
      final end = range[1];

      if (currentStart == null) {
        currentStart = start;
        currentEnd = end;
      } else {
        if (currentEnd == start) {
          currentEnd = end;
        } else {
          merged.add('$currentStart - $currentEnd');
          currentStart = start;
          currentEnd = end;
        }
      }
    }
    if (currentStart != null) {
      merged.add('$currentStart - $currentEnd');
    }

    return merged.join(', ');
  }

  Future<void> _approveRequest() async {
    setState(() => _isActionLoading = true);
    try {
      final bookingId = widget.booking['id'].toString();
      await context.read<BookingsCubit>().approveBooking(bookingId);
      if (mounted) {
        try {
          context.read<DashboardCubit>().fetchDashboardData();
        } catch (_) {}
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Request Approved! 🎉"),
          description: const Text("User has 45 minutes to complete payment."),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("Error approving request"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _declineRequest() async {
    setState(() => _isActionLoading = true);
    try {
      final bookingId = widget.booking['id'].toString();
      await context.read<BookingsCubit>().declineBooking(bookingId);
      if (mounted) {
        try {
          context.read<DashboardCubit>().fetchDashboardData();
        } catch (_) {}
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          title: const Text("Request Declined"),
          description: const Text("Booking declined and slots released."),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("Error declining request"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _openDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: widget.booking),
      ),
    );
    if (result == true && mounted) {
      try {
        context.read<DashboardCubit>().fetchDashboardData();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final playerName = booking['player_name'] ?? 'Customer';
    final groundName = booking['ground_name'] ?? 'Court';
    final rawPeriod = (booking['period'] ?? 'Time').toString();
    final period = _simplifyPeriod(rawPeriod.split('|').first);
    final sportName = (booking['sport_name'] ?? 'Sport').toString();
    final amount = booking['amount'] ?? booking['total_amount'] ?? 0;

    String displayId = booking['display_id']?.toString() ?? '';
    if (displayId.isEmpty) {
      final fullId = booking['id']?.toString() ?? '';
      displayId = fullId.length > 5 ? fullId.substring(0, 5).toUpperCase() : fullId;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          child: InkWell(
            onTap: _openDetails,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: const Color(0xFFFFB74D),
                  width: 1.5,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Orange accent bar on the left
                    Container(
                      width: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE65100),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.radiusLg),
                          bottomLeft: Radius.circular(AppSizes.radiusLg),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer name + Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: HugeIcon(
                                            icon: sportIcon(sportName),
                                            size: 16,
                                            color: const Color(0xFFE65100),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              text: playerName,
                                              size: 14,
                                              weight: FontWeight.w700,
                                              color: AppColors.textPrimaryLight,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            AppText(
                                              text: groundName,
                                              size: 12,
                                              color: AppColors.textSecondaryLight,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                    border: Border.all(color: const Color(0xFFFFB74D)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFE65100)),
                                      SizedBox(width: 4),
                                      AppText(
                                        text: "Requested",
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: Color(0xFFE65100),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),

                            // Slot time & Amount row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedClock01,
                                    size: 14,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppText(
                                      text: period,
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: AppColors.textPrimaryLight,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedMoneyBag01,
                                    size: 14,
                                    color: AppColors.primaryDarkGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  AppText(
                                    text: "₹$amount",
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: AppColors.primaryDarkGreen,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),

                            // Timer countdown banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFE65100)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: AppText(
                                      text: _remainingSeconds > 0
                                          ? "Expires in ${_formatTimer(_remainingSeconds)}"
                                          : "Request Expired",
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                  const AppText(
                                    text: "Max 45m",
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),

                            // Action buttons: Decline & Approve
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isActionLoading ? null : _declineRequest,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                      ),
                                    ),
                                    child: const AppText(
                                      text: "Decline",
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (_isActionLoading || _remainingSeconds <= 0)
                                        ? null
                                        : _approveRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryDarkGreen,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                      ),
                                    ),
                                    child: _isActionLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const AppText(
                                            text: "Approve",
                                            size: 12,
                                            weight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
