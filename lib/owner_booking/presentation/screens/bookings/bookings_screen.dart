import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/utils/booking_id_util.dart';
import 'package:turfpro_owner/common/utils/booking_time_util.dart';
import 'package:turfpro_owner/common/utils/booking_financial_util.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/status_badge.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';

import '../../blocs/location/location_cubit.dart';
import '../../blocs/location/location_state.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BookingsCubit>().fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: now, end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryDarkGreen),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    context.read<BookingsCubit>().setDateRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // ── Gradient header ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDarkGreen, Color(0xFF0FA968)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg,
              MediaQuery.of(context).padding.top + AppSizes.lg,
              AppSizes.lg,
              AppSizes.xl,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: "Bookings",
                            size: 22,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                          const SizedBox(height: 4),
                          BlocBuilder<LocationCubit, LocationState>(
                            builder: (context, locState) {
                              String locName = "All Locations";
                              if (locState is LocationLoaded) {
                                final selectedId = SharedPrefsService
                                    .instance
                                    .selectedLocationId;
                                if (selectedId != null) {
                                  try {
                                    final loc = locState.locations.firstWhere(
                                      (l) => l['id'] == selectedId,
                                    );
                                    if (loc['name'] != null &&
                                        loc['name'].toString().isNotEmpty) {
                                      locName = loc['name'];
                                    }
                                  } catch (_) {}
                                }
                              }
                              return Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AppText(
                                    text: locName,
                                    size: 12,
                                    color: AppColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<BookingsCubit, BookingsState>(
                      builder: (context, state) {
                        final count = state is BookingsLoaded
                            ? state.filteredBookings.length
                            : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: AppText(
                            text: "$count",
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
              0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  context.read<BookingsCubit>().searchBookings(query);
                },
                decoration: InputDecoration(
                  hintText: "Search player, ground or booking ID",
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<BookingsCubit>().searchBookings('');
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primaryDarkGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Date filter chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.md,
            ),
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                final dateFilter = state is BookingsLoaded
                    ? state.dateFilter
                    : BookingDateFilter.all;
                final rangeStart = state is BookingsLoaded
                    ? state.rangeStart
                    : null;
                final rangeEnd = state is BookingsLoaded
                    ? state.rangeEnd
                    : null;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DateFilterChip(
                        label: 'All',
                        selected: dateFilter == BookingDateFilter.all,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.all),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label:
                            state is BookingsLoaded &&
                                state.pendingRequestsCount > 0
                            ? 'Requests (${state.pendingRequestsCount})'
                            : 'Requests',
                        icon: Icons.hourglass_top_rounded,
                        selected: dateFilter == BookingDateFilter.requests,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.requests),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label: 'Today',
                        selected: dateFilter == BookingDateFilter.today,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.today),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label: 'Tomorrow',
                        selected: dateFilter == BookingDateFilter.tomorrow,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.tomorrow),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label:
                            dateFilter == BookingDateFilter.range &&
                                rangeStart != null &&
                                rangeEnd != null
                            ? '${DateFormat('d MMM').format(rangeStart)} – ${DateFormat('d MMM').format(rangeEnd)}'
                            : 'Date Range',
                        icon: Icons.date_range_rounded,
                        selected: dateFilter == BookingDateFilter.range,
                        onTap: _pickDateRange,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Booking list ──
          Expanded(
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                if (state is BookingsLoading) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.sm,
                      AppSizes.lg,
                      AppSizes.lg,
                    ),
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, index) => const _BookingSkeleton(),
                  );
                } else if (state is BookingsError) {
                  return Center(
                    child: AppText(text: state.message, color: AppColors.error),
                  );
                } else if (state is BookingsLoaded) {
                  if (state.filteredBookings.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xxxl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.xl),
                              decoration: BoxDecoration(
                                color: AppColors.borderLight.withValues(
                                  alpha: 0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch02,
                                size: 48,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),
                            AppText(
                              text: "No bookings found",
                              size: 16,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: AppSizes.xs),
                            AppText(
                              text: "Try adjusting your search or filters",
                              size: 13,
                              color: AppColors.borderLight,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<BookingsCubit>().fetchBookings();
                    },
                    color: AppColors.primaryDarkGreen,
                    child: _StaggeredBookingList(
                      bookings: state.filteredBookings
                          .cast<Map<String, dynamic>>(),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staggered entrance animation wrapper ──

class _StaggeredBookingList extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;

  const _StaggeredBookingList({required this.bookings});

  @override
  State<_StaggeredBookingList> createState() => _StaggeredBookingListState();
}

class _StaggeredBookingListState extends State<_StaggeredBookingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.bookings.length * 60),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StaggeredBookingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookings != widget.bookings) {
      _controller.reset();
      _controller.duration = Duration(
        milliseconds: 400 + widget.bookings.length * 60,
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _fadeIn,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.sm,
            AppSizes.lg,
            AppSizes.lg,
          ),
          itemCount: widget.bookings.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final start = index / widget.bookings.length;
            final end = (index + 1) / widget.bookings.length;
            final itemFade = Interval(
              start.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ).transform(_fadeIn.value);
            return Opacity(
              opacity: itemFade,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - itemFade)),
                child: _BookingCard(
                  key: ValueKey(widget.bookings[index]['id']),
                  booking: widget.bookings[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Booking card ──

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({super.key, required this.booking});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _pressed = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTimer();
  }

  @override
  void didUpdateWidget(_BookingCard oldWidget) {
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
    if (!s.endsWith('Z') &&
        !s.contains('+') &&
        !RegExp(r'-\d{2}:?\d{2}$').hasMatch(s)) {
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
    final status = (widget.booking['status'] ?? '').toString().toLowerCase();
    if (status == 'requested') {
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
              }
            }
          });
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _approveRequest() async {
    setState(() => _isActionLoading = true);
    try {
      final bookingId = widget.booking['id'].toString();
      await context.read<BookingsCubit>().approveBooking(bookingId);
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Request Approved!"),
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
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          title: const Text("Request Declined"),
          description: const Text("Booking cancelled and slots released."),
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
      context.read<BookingsCubit>().fetchBookings();
    }
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

  DateTime? _robustParse(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    debugPrint('[BOOKING_CARD] raw slot_time = $s');
    final candidates = <String>[
      s,
      if (!s.endsWith('Z') &&
          !s.contains('+') &&
          !RegExp(r'-\d{2}:?\d{2}$').hasMatch(s))
        '${s}Z',
      s.replaceFirst(' ', 'T'),
    ];
    for (final c in candidates) {
      final d = DateTime.tryParse(c);
      if (d != null) {
        final local = d.toLocal();
        debugPrint('[BOOKING_CARD] parsed = $local (from $c)');
        return local;
      }
    }
    debugPrint('[BOOKING_CARD] FAILED to parse slot_time: $s');
    return null;
  }

  String _formatBookingDate(DateTime? dt, String periodLabel) {
    if (dt != null) return DateFormat('EEE, MMM d').format(dt);
    if (periodLabel.isNotEmpty && periodLabel.toLowerCase() != 'day') {
      return periodLabel;
    }
    return 'Scheduled';
  }

  String _extractPeriodLabel(String period) {
    if (period.isEmpty) return 'Day';
    final pipeIdx = period.indexOf('|');
    if (pipeIdx < 0) return period;
    return period.substring(0, pipeIdx).trim();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = (booking['status'] ?? 'pending').toString();

    final playerName = booking['player_name']?.toString() ?? 'Player Name';
    final groundName = booking['ground_name']?.toString() ?? 'Court';
    final rawPeriod = (booking['period'] ?? '').toString();
    final periodLabel = _extractPeriodLabel(rawPeriod);
    final sportName = (booking['sport_name'] ?? booking['sport'] ?? 'Sport')
        .toString();
    final ownerEarnings = BookingFinancialUtil.getOwnerEarnings(booking);
    final displayAmount = BookingFinancialUtil.formatAmount(ownerEarnings);
    final pastBookings = booking['past_bookings'] ?? 0;

    debugPrint(
      '[BOOKING_CARD] player=$playerName status=$status period=$rawPeriod sport=$sportName',
    );

    final slotTime = _robustParse(booking['slot_time']);
    final dateText = _formatBookingDate(slotTime, periodLabel);

    final String timeDisplay = BookingTimeUtil.formatBookingTime(
      period: rawPeriod,
      slotTime: slotTime,
    );
    debugPrint('[BOOKING_CARD] date=$dateText time=$timeDisplay');

    final String displayId = BookingIdUtil.formatBookingId(
      booking['display_id'],
      booking['id'],
    );

    final statusColor = AppColors.bookingStatusColor(status);
    final outlineColor = statusColor.withValues(alpha: 0.35);

    const double barWidth = 6;
    const double outlineWidth = 1;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: InkWell(
            onTap: _openDetails,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            splashColor: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            highlightColor: AppColors.primaryDarkGreen.withValues(alpha: 0.03),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: outlineColor, width: outlineWidth),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg - outlineWidth),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: statusColor, width: barWidth),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.lg - (barWidth / 2 - outlineWidth).clamp(0, 8),
                      AppSizes.lg,
                      AppSizes.lg,
                      AppSizes.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // ── Header: sport tile + player/ground + status ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDarkGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
                                ),
                                child: SportIcon(
                                  sport: sportName,
                                  color: AppColors.primaryDarkGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      text: playerName,
                                      size: 15,
                                      weight: FontWeight.w700,
                                    ),
                                    const SizedBox(height: 2),
                                    AppText(
                                      text:
                                          "$groundName • ${formatSportName(sportName)}",
                                      size: 12,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    // ── Date + Time + Amount row ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            text: dateText,
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            color: AppColors.borderLight,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: timeDisplay.contains(',')
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: timeDisplay
                                        .split(',')
                                        .map(
                                          (t) => Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: AppText(
                                              text: t.trim(),
                                              size: 12,
                                              weight: FontWeight.w600,
                                              color: AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  )
                                : AppText(
                                    text: timeDisplay,
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: AppColors.textPrimaryLight,
                                  ),
                          ),
                          AppText(
                            text: "₹$displayAmount",
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // ── Footer: booking id / customer tag / view details ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: AppSizes.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.borderLight,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusXs,
                                ),
                              ),
                              child: AppText(
                                text: "CB$displayId",
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: AppSizes.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: pastBookings > 0
                                    ? AppColors.slotAvailableBg
                                    : AppColors.statusPendingBg,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusXs,
                                ),
                                border: Border.all(
                                  color: pastBookings > 0
                                      ? AppColors.slotAvailableBorder
                                      : AppColors.statusPendingBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: AppText(
                                text: pastBookings > 0
                                    ? "$pastBookings past bookings"
                                    : "New Customer",
                                size: 10,
                                weight: FontWeight.w700,
                                color: pastBookings > 0
                                    ? AppColors.statusConfirmed
                                    : AppColors.statusPending,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              text: "View Details",
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.primaryDarkGreen,
                            ),
                            const SizedBox(width: AppSizes.xxs),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Requested-state timer + actions ──
                    if (status.toLowerCase() == 'requested') ...[
                      const SizedBox(height: AppSizes.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingBg,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.statusPendingBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppColors.statusPending,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AppText(
                                text: _remainingSeconds > 0
                                    ? "Expires in ${_formatTimer(_remainingSeconds)}"
                                    : "Request Expired",
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.statusPending,
                              ),
                            ),
                            AppText(
                              text: "Max 45m",
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.statusPending,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isActionLoading
                                  ? null
                                  : _declineRequest,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
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
                              onPressed:
                                  (_isActionLoading || _remainingSeconds <= 0)
                                  ? null
                                  : _approveRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDarkGreen,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}

// ── Date filter chip (pill style) ──

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _DateFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkGreen : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.primaryDarkGreen
                : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selected && icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textSecondaryLight),
              const SizedBox(width: 5),
            ],
            AppText(
              text: label,
              size: 13,
              weight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.textPrimaryLight,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Info chip ──

class _InfoChip extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, size: 13, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        AppText(text: text, size: 12, color: AppColors.textSecondaryLight),
      ],
    );
  }
}

// ── Skeleton ──

class _BookingSkeleton extends StatelessWidget {
  const _BookingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLg),
                  bottomLeft: Radius.circular(AppSizes.radiusLg),
                ),
              ),
            ),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: AppColors.borderLight,
                highlightColor: AppColors.borderLight.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Container(
                        width: 180,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusXs,
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
