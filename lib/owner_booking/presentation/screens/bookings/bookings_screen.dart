import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/utils/sport_icon.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/status_badge.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
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
    context.read<LocationCubit>().fetchOwnerLocations();
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
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryDarkGreen,
              ),
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
                colors: [
                  AppColors.primaryDarkGreen,
                  Color(0xFF0FA968),
                ],
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
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                      child: AppText(
                        text: "Bookings",
                        size: 22,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    BlocBuilder<BookingsCubit, BookingsState>(
                      builder: (context, state) {
                        final count = state is BookingsLoaded
                            ? state.filteredBookings.length
                            : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
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
                const SizedBox(height: AppSizes.md),
                BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, locState) {
                    if (locState is LocationLoaded) {
                      return LocationDropdown(
                        locations: locState.locations.cast<Map<String, dynamic>>(),
                        selectedLocationId: SharedPrefsService.instance.selectedLocationId,
                        onSelected: (id) {
                          SharedPrefsService.instance.setSelectedLocationId(id);
                          setState(() {});
                          context.read<BookingsCubit>().fetchBookings();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.lg, AppSizes.lg, 0),
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
                                AppSizes.radiusFull),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.textSecondaryLight),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<BookingsCubit>()
                              .searchBookings('');
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                        color: AppColors.primaryDarkGreen, width: 1.2),
                  ),
                ),
              ),
            ),
          ),

          // ── Date filter chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.md),
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                final dateFilter = state is BookingsLoaded
                    ? state.dateFilter
                    : BookingDateFilter.all;
                final rangeStart =
                    state is BookingsLoaded ? state.rangeStart : null;
                final rangeEnd =
                    state is BookingsLoaded ? state.rangeEnd : null;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DateFilterChip(
                        label: 'All',
                        selected:
                            dateFilter == BookingDateFilter.all,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.all),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label: 'Today',
                        selected: dateFilter ==
                            BookingDateFilter.today,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(BookingDateFilter.today),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label: 'Tomorrow',
                        selected: dateFilter ==
                            BookingDateFilter.tomorrow,
                        onTap: () => context
                            .read<BookingsCubit>()
                            .setDateFilter(
                                BookingDateFilter.tomorrow),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DateFilterChip(
                        label: dateFilter ==
                                    BookingDateFilter.range &&
                                rangeStart != null &&
                                rangeEnd != null
                            ? '${DateFormat('d MMM').format(rangeStart)} – ${DateFormat('d MMM').format(rangeEnd)}'
                            : 'Date Range',
                        icon: Icons.date_range_rounded,
                        selected: dateFilter ==
                            BookingDateFilter.range,
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
                        AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.lg),
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, index) =>
                        const _BookingSkeleton(),
                  );
                } else if (state is BookingsError) {
                  return Center(
                    child: AppText(
                        text: state.message, color: AppColors.error),
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
                                color: AppColors.borderLight
                                    .withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons
                                    .strokeRoundedSearch02,
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
                              text:
                                  "Try adjusting your search or filters",
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
                      await context
                          .read<BookingsCubit>()
                          .fetchBookings();
                    },
                    color: AppColors.primaryDarkGreen,
                    child: _StaggeredBookingList(
                      bookings: state.filteredBookings.cast<Map<String, dynamic>>(),
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
          milliseconds: 400 + widget.bookings.length * 60);
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
              AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.lg),
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
                child: _BookingCard(booking: widget.bookings[index]),
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

  const _BookingCard({required this.booking});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _pressed = false;

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingDetailsScreen(booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = (booking['status'] ?? 'pending').toString();

    final playerName = booking['player_name'] ?? 'Player Name';
    final groundName = booking['ground_name'] ?? 'Court';
    final period = booking['period'] ?? 'Time';
    final sportName = booking['sport_name'] ?? 'Sport';
    final amount = booking['amount'] ?? booking['total_amount'] ?? 0;

    String displayId = booking['display_id']?.toString() ?? '';
    if (displayId.isEmpty) {
      final fullId = booking['id']?.toString() ?? '';
      displayId = fullId.length > 5
          ? fullId.substring(0, 5).toUpperCase()
          : fullId;
    }

    final statusColor = AppColors.bookingStatusColor(status);

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
            borderRadius:
                BorderRadius.circular(AppSizes.radiusLg),
            splashColor:
                AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            highlightColor:
                AppColors.primaryDarkGreen.withValues(alpha: 0.03),
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left color accent bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.radiusLg),
                          bottomLeft:
                              Radius.circular(AppSizes.radiusLg),
                        ),
                      ),
                    ),
                    // Card content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Player name + status badge
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: AppText(
                                    text: playerName,
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                StatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xs),

                            // Ground + time
                            AppText(
                              text: "$groundName • $period",
                              size: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Info chips in tinted row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md,
                                  vertical: AppSizes.sm),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  _InfoChip(
                                    icon: sportIcon(
                                        sportName.toString()),
                                    text: formatSportName(
                                        sportName.toString()),
                                  ),
                                  const SizedBox(width: AppSizes.lg),
                                  _InfoChip(
                                    icon: HugeIcons
                                        .strokeRoundedUserGroup,
                                    text: "Players",
                                  ),
                                  const SizedBox(width: AppSizes.lg),
                                  _InfoChip(
                                    icon: HugeIcons
                                        .strokeRoundedMoneyBag01,
                                    text: "₹$amount",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Booking ID tag + View Details
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: AppSizes.xxs),
                                  decoration: BoxDecoration(
                                    color: AppColors.borderLight,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppSizes.radiusXs),
                                  ),
                                  child: AppText(
                                    text: "CB$displayId",
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color:
                                        AppColors.textSecondaryLight,
                                  ),
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
                                      color:
                                          AppColors.primaryDarkGreen,
                                    ),
                                  ],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryDarkGreen : AppColors.surfaceLight,
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
                    color: AppColors.primaryDarkGreen
                        .withValues(alpha: 0.15),
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
              Icon(
                icon,
                size: 14,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 5),
            ],
            AppText(
              text: label,
              size: 13,
              weight: FontWeight.w600,
              color:
                  selected ? AppColors.white : AppColors.textPrimaryLight,
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
        HugeIcon(
            icon: icon,
            size: 13,
            color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        AppText(
          text: text,
          size: 12,
          color: AppColors.textSecondaryLight,
        ),
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
                highlightColor:
                    AppColors.borderLight.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
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
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusXs),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(4),
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
